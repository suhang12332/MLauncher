import Foundation
import os

// AsyncSemaphore for Swift Concurrency
actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(value: Int) {
        self.value = value
    }

    func wait() async {
        if value > 0 {
            value -= 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func signal() {
        if !waiters.isEmpty {
            let continuation = waiters.removeFirst()
            continuation.resume()
        } else {
            value += 1
        }
    }
}

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

            // 2. 获取主mod详情
            let mainProjectDetail = try await ModrinthService.fetchProjectDetails(id: projectId)

            // 3. 读取最大并发数，最少为1
            let maxConcurrent = max(1, GameSettingsManager.shared.concurrentDownloads)
            let semaphore = AsyncSemaphore(value: maxConcurrent) // 控制最大并发数

            // 4. 并发下载所有依赖和主mod，收集结果
            let allDownloaded: [ModrinthProjectDetail] = await withTaskGroup(of: ModrinthProjectDetail?.self) { group in
                // 依赖
                for dep in missing {
                    group.addTask {
                        await semaphore.wait() // 限制并发
                        defer { Task { await semaphore.signal() } }
                        let versions = try? await ModrinthService.fetchProjectVersions(id: dep.id)
                        let filtered = versions?.filter { version in
                            version.loaders.contains(gameInfo.modLoader) && version.gameVersions.contains(gameInfo.gameVersion)
                        }
                        if let latest = filtered?.first, let fileURL = latest.files.first?.url {
                            _ = try? await DownloadManager.downloadResource(
                                for: gameInfo,
                                urlString: fileURL,
                                resourceType: query
                            )
                            return dep
                        }
                        return nil
                    }
                }
                // 主mod
                group.addTask {
                    await semaphore.wait() // 限制并发
                    defer { Task { await semaphore.signal() } }
                    let filteredVersions = try? await ModrinthService.fetchProjectVersionsFilter(
                        id: projectId,
                        selectedVersions: [gameInfo.gameVersion],
                        selectedLoaders: [gameInfo.modLoader]
                    )
                    if let latestVersion = filteredVersions?.first,
                       let fileURL = latestVersion.files.first?.url {
                        _ = try? await DownloadManager.downloadResource(
                            for: gameInfo,
                            urlString: fileURL,
                            resourceType: query
                        )
                        return mainProjectDetail
                    }
                    return nil
                }
                // 收集所有下载结果
                var localResults: [ModrinthProjectDetail] = []
                for await result in group {
                    if let project = result {
                        localResults.append(project)
                    }
                }
                return localResults
            }

            // 5. 批量 addResource
            await MainActor.run {
                for var resource in allDownloaded {
                    resource.type = query
                    _ = gameRepository.addResource(id: gameInfo.id, resource: resource)
                }
            }
            actuallyDownloaded.append(contentsOf: allDownloaded)
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
