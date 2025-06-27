import Foundation
import os

struct ModrinthDependencyDownloader {
    /// 递归下载所有依赖（基于官方依赖API）
    static func downloadAllDependenciesRecursive(
        for projectId: String,
        gameInfo: GameVersionInfo,
        query: String,
        gameRepository: GameRepository,
        actuallyDownloaded: inout [ModrinthProjectDetail]
    ) async {
        do {
            // 1. 获取所有依赖
            let dependencies = try await ModrinthService.fetchProjectDependencies(id: projectId)
            let localProjectIds = Set(gameInfo.resources.map { $0.id })
            let missing = dependencies.projects.filter { !localProjectIds.contains($0.id) }
            var downloadedDeps: [ModrinthProjectDetail] = []
            for dep in missing {
                // 只下载直接依赖，不递归
                let versions = try await ModrinthService.fetchProjectVersions(id: dep.id)
                // 增加筛选：只保留符合 loader 和 gameVersion 的版本
                let filtered = versions.filter { version in
                    version.loaders.contains(gameInfo.modLoader) && version.gameVersions.contains(gameInfo.gameVersion)
                }
                guard let latest = filtered.first, let fileURL = latest.files.first?.url else { continue }
                _ = try await DownloadManager.downloadResource(
                    for: gameInfo,
                    urlString: fileURL,
                    resourceType: query
                )
                downloadedDeps.append(dep)
            }
            
            // 下载主mod本体
            let filteredVersions = try await ModrinthService.fetchProjectVersionsFilter(
                id: projectId,
                selectedVersions: [gameInfo.gameVersion],
                selectedLoaders: [gameInfo.modLoader]
            )
            var mainProject: ModrinthProjectDetail? = nil
            if let latestVersion = filteredVersions.first,
               let fileURL = latestVersion.files.first?.url {
                _ = try await DownloadManager.downloadResource(
                    for: gameInfo,
                    urlString: fileURL,
                    resourceType: query
                )
                // 获取主mod详情
                let mainProjectDetail = try await ModrinthService.fetchProjectDetails(id: projectId)
                mainProject = mainProjectDetail
            }
            // 合并依赖和主mod，一起添加到资源库
            var allResources = downloadedDeps
            if let main = mainProject {
                allResources.append(main)
            }
            let resourcesToAdd = allResources
            await MainActor.run {
                for resource in resourcesToAdd {
                    _ = gameRepository.addResource(id: gameInfo.id, resource: resource)
                }
            }
            actuallyDownloaded.append(contentsOf: allResources)
        } catch {
            Logger.shared.error("下载依赖 projectId=\(projectId) 时出错: \(error)")
        }
    }

    /// 获取当前项目缺失的直接依赖（不递归，仅一层）
    static func getMissingDependencies(
        for projectId: String,
        gameInfo: GameVersionInfo
    ) async throws -> [ModrinthProjectDetail] {
        let dependencies = try await ModrinthService.fetchProjectDependencies(id: projectId)
        let localProjectIds = Set(gameInfo.resources.map { $0.id })
        let missing = dependencies.projects.filter { !localProjectIds.contains($0.id) }
        return missing
    }
} 
