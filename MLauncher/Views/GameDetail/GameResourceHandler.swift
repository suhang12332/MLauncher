import Foundation
import SwiftUI

struct GameResourceHandler {
    static func updateButtonState(
        gameInfo: GameVersionInfo?,
        project: ModrinthProject,
        gameRepository: GameRepository,
        addButtonState: inout ModrinthDetailCardView.AddButtonState
    ) {
        guard let gameInfo = gameInfo,
              let latestGame = gameRepository.getGame(by: gameInfo.id) else { return }
        if latestGame.resources.contains(where: { $0.id == project.projectId }) {
            addButtonState = .installed
        } else if addButtonState == .installed {
            addButtonState = .idle
        }
    }

    static func performDelete(
        gameInfo: GameVersionInfo?,
        project: ModrinthProject,
        gameRepository: GameRepository
    ) {
        guard let game = gameInfo else { return }
        _ = gameRepository.removeResource(id: game.id, projectId: project.projectId)
    }

    @MainActor
    static func downloadWithDependencies(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        query: String,
        gameRepository: GameRepository,
        updateButtonState: @escaping () -> Void
    ) async {
        guard let gameInfo = gameInfo else { return }
        var actuallyDownloaded: [ModrinthProjectDetail] = []
        var visited: Set<String> = []
        await ModrinthDependencyDownloader.downloadAllDependenciesRecursive(
            for: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository,
            actuallyDownloaded: &actuallyDownloaded,
            visited: &visited
        )
        updateButtonState()
    }

    @MainActor
    static func downloadSingleResource(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        query: String,
        gameRepository: GameRepository,
        updateButtonState: @escaping () -> Void
    ) async {
        guard let gameInfo = gameInfo else { return }
        
        let success = await ModrinthDependencyDownloader.downloadMainResourceOnly(
            mainProjectId: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository,
            filterLoader: query != "shader"
        )
        
        if success {
            updateButtonState()
        } else {
            Logger.shared.error("直接下载资源 \(project.title) 失败")
            updateButtonState()
        }
    }

    @MainActor
    static func prepareManualDependencies(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        depVM: DependencySheetViewModel
    ) async -> Bool {
        guard let gameInfo = gameInfo else { return false }
        depVM.isLoadingDependencies = true
        do {
            let missing = try await ModrinthDependencyDownloader.getMissingDependencies(
                for: project.projectId,
                gameInfo: gameInfo
            )
            let filtered = missing.filter {
                $0.loaders.contains(gameInfo.modLoader) && $0.gameVersions.contains(gameInfo.gameVersion)
            }
            if filtered.isEmpty {
                depVM.isLoadingDependencies = false
                return false
            }
            var versionDict: [String: [ModrinthProjectDetailVersion]] = [:]
            var selectedVersionDict: [String: String] = [:]
            for dep in filtered {
                let versions = try? await ModrinthService.fetchProjectVersions(id: dep.id)
                let filteredVersions = versions?.filter {
                    $0.loaders.contains(gameInfo.modLoader) && $0.gameVersions.contains(gameInfo.gameVersion)
                } ?? []
                versionDict[dep.id] = filteredVersions
                if let first = filteredVersions.first {
                    selectedVersionDict[dep.id] = first.id
                }
            }
            depVM.missingDependencies = filtered
            depVM.dependencyVersions = versionDict
            depVM.selectedDependencyVersion = selectedVersionDict
            depVM.isLoadingDependencies = false
            depVM.resetDownloadStates()
            return true
        } catch {
            depVM.missingDependencies = []
            depVM.dependencyVersions = [:]
            depVM.selectedDependencyVersion = [:]
            depVM.isLoadingDependencies = false
            depVM.resetDownloadStates()
            return false
        }
    }

    @MainActor
    static func downloadAllDependenciesAndMain(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        depVM: DependencySheetViewModel,
        query: String,
        gameRepository: GameRepository,
        updateButtonState: @escaping () -> Void
    ) async {
        guard let gameInfo = gameInfo else { return }
        let dependencies = depVM.missingDependencies
        let selectedVersions = depVM.selectedDependencyVersion
        let dependencyVersions = depVM.dependencyVersions

        let allSucceeded = await ModrinthDependencyDownloader.downloadManualDependenciesAndMain(
            dependencies: dependencies,
            selectedVersions: selectedVersions,
            dependencyVersions: dependencyVersions,
            mainProjectId: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository,
            onDependencyDownloadStart: { depId in
                depVM.dependencyDownloadStates[depId] = .downloading
            },
            onDependencyDownloadFinish: { depId, success in
                depVM.dependencyDownloadStates[depId] = success ? .success : .failed
            }
        )

        if allSucceeded {
            updateButtonState()
            depVM.showDependenciesSheet = false
        } else {
            depVM.overallDownloadState = .failed
        }
    }
    
    @MainActor
    static func downloadMainResourceAfterDependencies(
        project: ModrinthProject,
        gameInfo: GameVersionInfo?,
        depVM: DependencySheetViewModel,
        query: String,
        gameRepository: GameRepository,
        updateButtonState: @escaping () -> Void
    ) async {
        guard let gameInfo = gameInfo else { return }
        
        let success = await ModrinthDependencyDownloader.downloadMainResourceOnly(
            mainProjectId: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository
        )
        
        if success {
            updateButtonState()
            depVM.showDependenciesSheet = false
        } else {
            Logger.shared.error("主资源下载失败，请重试。")
        }
    }

    @MainActor
    static func retryDownloadDependency(
        dep: ModrinthProjectDetail,
        gameInfo: GameVersionInfo?,
        depVM: DependencySheetViewModel,
        query: String,
        gameRepository: GameRepository
    ) async {
        guard let gameInfo = gameInfo,
              let versionId = depVM.selectedDependencyVersion[dep.id],
              let versions = depVM.dependencyVersions[dep.id],
              let version = versions.first(where: { $0.id == versionId }),
              let primaryFile = ModrinthService.filterPrimaryFiles(from: version.files) else {
            depVM.dependencyDownloadStates[dep.id] = .failed
            return
        }
        depVM.dependencyDownloadStates[dep.id] = .downloading
        do {
            _ = try await DownloadManager.downloadResource(
                for: gameInfo,
                urlString: primaryFile.url,
                resourceType: dep.projectType ?? query,
                expectedSha1: primaryFile.hashes.sha1
            )
            
            var resourceToAdd = dep
            resourceToAdd.fileName = primaryFile.filename
            resourceToAdd.type = dep.projectType ?? query
            
            _ = gameRepository.addResource(id: gameInfo.id, resource: resourceToAdd)
            
            depVM.dependencyDownloadStates[dep.id] = .success
        } catch {
            depVM.dependencyDownloadStates[dep.id] = .failed
        }
    }
} 
