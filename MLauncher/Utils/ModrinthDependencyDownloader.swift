import Foundation
import os


struct ModrinthDependencyDownloader {
    /// 递归下载所有依赖（基于官方依赖API）
    static func downloadAllDependenciesRecursive(
        for projectId: String,
        gameInfo: GameVersionInfo,
        query: String,
        gameRepository: GameRepository,
        actuallyDownloaded: inout [ModrinthProjectDetail],
        visited: inout Set<String>
    ) async {
        do {
            // 1. 获取所有依赖
            let dependencies = try await ModrinthService.fetchProjectDependencies(id: projectId)
            let localProjectIds = Set(gameInfo.resources.map { $0.id })
            let missing = dependencies.projects.filter { !localProjectIds.contains($0.id) }

            // 2. 获取主mod详情
            var mainProjectDetail = try await ModrinthService.fetchProjectDetails(id: projectId)

            // 3. 读取最大并发数，最少为1
            let semaphore = AsyncSemaphore(value: GameSettingsManager.shared.concurrentDownloads) // 控制最大并发数

            // 4. 并发下载所有依赖和主mod，收集结果
            let allDownloaded: [ModrinthProjectDetail] = await withTaskGroup(of: ModrinthProjectDetail?.self) { group in
                // 依赖
                for var dep in missing {
                    group.addTask {
                        await semaphore.wait() // 限制并发
                        defer { Task { await semaphore.signal() } }
                        
                        // 检查依赖是否有版本信息，如果有则直接使用
                        // 没有版本信息，需要获取版本
                        let versions = try? await ModrinthService.fetchProjectVersionsFilter(
                            id: dep.id,
                            selectedVersions: [gameInfo.gameVersion],
                            selectedLoaders: [gameInfo.modLoader])
                        
                        let result = ModrinthService.filterPrimaryFiles(from: versions?.first?.files)
                        if let file = result {
                            _ = try? await DownloadManager.downloadResource(
                for: gameInfo,
                                urlString: file.url,
                                resourceType: query,
                                expectedSha1: file.hashes.sha1
                            )
                            dep.fileName = file.filename
                            dep.type = query
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
                    let result = ModrinthService.filterPrimaryFiles(from: filteredVersions?.first?.files)
                    if let file = result {
                        _ = try? await DownloadManager.downloadResource(
                    for: gameInfo,
                            urlString: file.url,
                            resourceType: query,
                            expectedSha1: file.hashes.sha1
                        )
                        mainProjectDetail.fileName = file.filename
                        mainProjectDetail.type = query
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
                for resource in allDownloaded {
                    _ = gameRepository.addResource(id: gameInfo.id, resource: resource)
                }
                gameRepository.objectWillChange.send() // 强制刷新所有依赖和主依赖的按钮状态
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

    /// 手动下载依赖和主mod（不递归，仅当前依赖和主mod）
    static func downloadManualDependenciesAndMain(
        dependencies: [ModrinthProjectDetail],
        selectedVersions: [String: String],
        dependencyVersions: [String: [ModrinthProjectDetailVersion]],
        mainProjectId: String,
        gameInfo: GameVersionInfo,
        query: String,
        gameRepository: GameRepository,
        onDependencyDownloadStart: @escaping (String) -> Void,
        onDependencyDownloadFinish: @escaping (String, Bool) -> Void
    ) async -> Bool {
        var resourcesToAdd: [ModrinthProjectDetail] = []
        var allSuccess = true
        let semaphore = AsyncSemaphore(value: GameSettingsManager.shared.concurrentDownloads)
        
        await withTaskGroup(of: (String, Bool, ModrinthProjectDetail?).self) { group in
            for var dep in dependencies {
                guard let versionId = selectedVersions[dep.id],
                      let versions = dependencyVersions[dep.id],
                      let version = versions.first(where: { $0.id == versionId }),
                      let primaryFile = ModrinthService.filterPrimaryFiles(from: version.files) else {
                    allSuccess = false
                    Task { @MainActor in
                        onDependencyDownloadFinish(dep.id, false)
                        }
                    continue
                }
                
                        group.addTask {
                    await MainActor.run { onDependencyDownloadStart(dep.id) }
                            await semaphore.wait()
                            defer { Task { await semaphore.signal() } }
                    
                            var success = false
                            do {
                                _ = try await DownloadManager.downloadResource(
                                    for: gameInfo,
                                    urlString: primaryFile.url,
                            resourceType: dep.projectType ?? query,
                                    expectedSha1: primaryFile.hashes.sha1
                                )
                        dep.fileName = primaryFile.filename
                        dep.type = dep.projectType ?? query
                                success = true
                            } catch {
                                success = false
                    }
                    return (dep.id, success, success ? dep : nil)
                }
            }
            
            for await (depId, success, depCopy) in group {
                await MainActor.run {
                    onDependencyDownloadFinish(depId, success)
                }
                if success, let depCopy = depCopy {
                    resourcesToAdd.append(depCopy)
                } else {
                    allSuccess = false
            }
        }
        }

        guard allSuccess else {
            // 如果依赖下载失败，就不再继续下载主mod，直接返回失败
            // 但需要将已成功的资源加入仓库
            await MainActor.run {
                for resource in resourcesToAdd {
                    _ = gameRepository.addResource(id: gameInfo.id, resource: resource)
                }
            }
            return false
        }
        
        // 所有依赖都成功了，现在下载主 mod
        do {
            var mainProjectDetail = try await ModrinthService.fetchProjectDetails(id: mainProjectId)
            guard let filteredVersions = try? await ModrinthService.fetchProjectVersionsFilter(
                id: mainProjectId,
                selectedVersions: [gameInfo.gameVersion],
                selectedLoaders: [gameInfo.modLoader]
            ), let latestVersion = filteredVersions.first, let primaryFile = ModrinthService.filterPrimaryFiles(from: latestVersion.files) else {
                return false
            }
            
            _ = try await DownloadManager.downloadResource(
                for: gameInfo,
                urlString: primaryFile.url,
                resourceType: query,
                expectedSha1: primaryFile.hashes.sha1
            )
            mainProjectDetail.fileName = primaryFile.filename
            mainProjectDetail.type = query
            resourcesToAdd.append(mainProjectDetail)
            
            // 批量 addResource
            await MainActor.run {
                for resource in resourcesToAdd {
                    _ = gameRepository.addResource(id: gameInfo.id, resource: resource)
                }
            }
            return true
        } catch {
            Logger.shared.error("下载主资源 \(mainProjectId) 失败: \(error)")
            return false
        }
    }
    
    static func downloadMainResourceOnly(
        mainProjectId: String,
        gameInfo: GameVersionInfo,
        query: String,
        gameRepository: GameRepository,
        filterLoader: Bool = true
    ) async -> Bool {
        do {
            var mainProjectDetail = try await ModrinthService.fetchProjectDetails(id: mainProjectId)
            let selectedLoaders = filterLoader ? [gameInfo.modLoader] : []
            guard let filteredVersions = try? await ModrinthService.fetchProjectVersionsFilter(
                id: mainProjectId,
                selectedVersions: [gameInfo.gameVersion],
                selectedLoaders: selectedLoaders
            ), let latestVersion = filteredVersions.first, let primaryFile = ModrinthService.filterPrimaryFiles(from: latestVersion.files) else {
                return false
            }
            
            _ = try await DownloadManager.downloadResource(
                for: gameInfo,
                urlString: primaryFile.url,
                resourceType: query,
                expectedSha1: primaryFile.hashes.sha1
            )
            mainProjectDetail.fileName = primaryFile.filename
            mainProjectDetail.type = query
            
            await MainActor.run {
                _ = gameRepository.addResource(id: gameInfo.id, resource: mainProjectDetail)
            }
            return true
        } catch {
            Logger.shared.error("仅下载主资源 \(mainProjectId) 失败: \(error)")
            return false
        }
    }
}

