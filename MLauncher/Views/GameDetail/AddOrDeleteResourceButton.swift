import SwiftUI
import Foundation
import os

// 新增依赖管理ViewModel，持久化依赖相关状态
final class DependencySheetViewModel: ObservableObject {
    @Published var missingDependencies: [ModrinthProjectDetail] = []
    @Published var isLoadingDependencies = true
    @Published var showDependenciesSheet = false
    @Published var dependencyDownloadStates: [String: ResourceDownloadState] = [:]
    @Published var dependencyVersions: [String: [ModrinthProjectDetailVersion]] = [:]
    @Published var selectedDependencyVersion: [String: String] = [:]

    func resetDownloadStates() {
        for dep in missingDependencies {
            dependencyDownloadStates[dep.id] = .idle
        }
    }
}

// 1. 下载状态定义
enum ResourceDownloadState {
    case idle, downloading, success, failed
}

struct AddOrDeleteResourceButton: View {
    var project: ModrinthProject
    let selectedVersions: [String]
    let selectedLoaders: [String]
    let gameInfo: GameVersionInfo?
    let query: String
    let type: Bool  // false = local, true = server
    @EnvironmentObject private var gameRepository: GameRepository
    @State private var addButtonState: ModrinthDetailCardView.AddButtonState = .idle
    @State private var showDeleteAlert = false
    @ObservedObject private var gameSettings = GameSettingsManager.shared
    @StateObject private var depVM = DependencySheetViewModel()
    
    var body: some View {
        Button(action: handleButtonAction) {
            buttonLabel
        }
        .buttonStyle(.borderedProminent)
        .font(.caption2)
        .controlSize(.small)
        .disabled(addButtonState == .loading || (addButtonState == .installed && type))  // type = true (server mode) disables deletion
        .onAppear(perform: updateButtonState)
        .onReceive(gameRepository.objectWillChange) { _ in updateButtonState() }
        .alert(isPresented: $showDeleteAlert) { deleteAlert }
        .sheet(isPresented: $depVM.showDependenciesSheet) { dependencySheet }
    }
    
    // MARK: - UI Components
    private var buttonLabel: some View {
        switch addButtonState {
        case .idle:
            AnyView(Text("resource.add".localized()))
        case .loading:
            AnyView(ProgressView())
        case .installed:
            AnyView(Text((!type ? "common.delete" : "resource.installed").localized()))
        }
    }

    private var deleteAlert: Alert {
        Alert(
            title: Text("common.delete".localized()),
            message: Text(String(format: "resource.delete.confirm".localized(), project.title)),
            primaryButton: .destructive(Text("common.delete".localized())) { removeResource() },
            secondaryButton: .cancel()
        )
    }

    private var dependencySheet: some View {
        CommonSheetView(
            header: {
                Text("待下载的前置mod(必须)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            },
            body: {
                if depVM.isLoadingDependencies || depVM.missingDependencies.isEmpty {
                    ProgressView().frame(height: 100).controlSize(.small)
                } else {
                    VStack {
                        ForEach(depVM.missingDependencies, id: \ .id) { dep in
                            let versions = depVM.dependencyVersions[dep.id] ?? []
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dep.title).font(.headline)
                                Picker("选择版本:", selection: Binding(
                                    get: { depVM.selectedDependencyVersion[dep.id] ?? "" },
                                    set: { depVM.selectedDependencyVersion[dep.id] = $0 }
                                )) {
                                    ForEach(versions, id: \.id) { v in
                                        Text(v.versionNumber).tag(v.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .font(.subheadline)
                            }
                        }
                    }
                }
            },
            footer: {
                if !depVM.isLoadingDependencies && !depVM.missingDependencies.isEmpty {
                    HStack {
                        Button("关闭") { depVM.showDependenciesSheet = false }
                        Spacer()
                        Button("下载所有依赖并继续") {
                            Task { await downloadAllDependenciesAndMain() }
                        }
                        .disabled(depVM.missingDependencies.contains { dep in
                            depVM.dependencyDownloadStates[dep.id] == .downloading
                        })
                    }
                } else {
                    HStack {
                        Spacer()
                        Button("关闭") { depVM.showDependenciesSheet = false }
                    }
                }
            }
        )
        .onAppear {
            depVM.isLoadingDependencies = true
            depVM.resetDownloadStates()
            Task { await prepareManualDependencies() }
        }
    }

    // MARK: - Actions
    private func handleButtonAction() {
        switch addButtonState {
        case .idle:
            if gameSettings.autoDownloadDependencies {
                addButtonState = .loading
                Task { await downloadWithDependencies() }
            } else {
                depVM.showDependenciesSheet = true
                Task { await prepareManualDependencies() }
            }
        case .installed:
            if !type { showDeleteAlert = true }
        default:
            break
        }
    }

    private func updateButtonState() {
        guard let gameInfo = gameInfo,
              let latestGame = gameRepository.getGame(by: gameInfo.id) else { return }
        if latestGame.resources.contains(where: { $0.id == project.projectId }) {
            addButtonState = .installed
        } else if addButtonState == .installed {
            addButtonState = .idle
        }
    }

    private func removeResource() {
        guard let gameInfo = gameInfo else { return }
        if let resource = gameInfo.resources.first(where: { $0.id == project.projectId }) {
            ResourceFileManager.deleteResourceFile(for: gameInfo, resource: resource)
        }
        _ = gameRepository.removeResource(id: gameInfo.id, projectId: project.projectId)
        addButtonState = .idle
    }

    private func downloadWithDependencies() async {
        guard let gameInfo = gameInfo else { return }
        var actuallyDownloaded: [ModrinthProjectDetail] = []
        await ModrinthDependencyDownloader.downloadAllDependenciesRecursive(
            for: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository,
            actuallyDownloaded: &actuallyDownloaded
        )
        await MainActor.run { updateButtonState() }
    }

    private func prepareManualDependencies() async {
        guard let gameInfo = gameInfo else { return }
        do {
            let missing = try await ModrinthDependencyDownloader.getMissingDependencies(
                for: project.projectId,
                gameInfo: gameInfo
            )
            let filtered = missing.filter {
                $0.loaders.contains(gameInfo.modLoader) && $0.gameVersions.contains(gameInfo.gameVersion)
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
            await MainActor.run {
                depVM.missingDependencies = filtered
                depVM.dependencyVersions = versionDict
                depVM.selectedDependencyVersion = selectedVersionDict
                depVM.isLoadingDependencies = false
            }
        } catch {
            await MainActor.run {
                depVM.missingDependencies = []
                depVM.dependencyVersions = [:]
                depVM.selectedDependencyVersion = [:]
                depVM.isLoadingDependencies = false
            }
        }
    }

    private func downloadAllDependenciesAndMain() async {
        depVM.isLoadingDependencies = true
        guard let gameInfo = gameInfo else { return }
        await withTaskGroup(of: Void.self) { group in
            for dep in depVM.missingDependencies {
                if let versionId = depVM.selectedDependencyVersion[dep.id],
                   let versions = depVM.dependencyVersions[dep.id],
                   let version = versions.first(where: { $0.id == versionId }),
                   let fileURL = version.files.first?.url {
                    group.addTask {
                        await MainActor.run { depVM.dependencyDownloadStates[dep.id] = .downloading }
                        do {
                            _ = try await DownloadManager.downloadResource(
                                for: gameInfo,
                                urlString: fileURL,
                                resourceType: query
                            )
                            await MainActor.run { depVM.dependencyDownloadStates[dep.id] = .success }
                        } catch {
                            await MainActor.run { depVM.dependencyDownloadStates[dep.id] = .failed }
                        }
                    }
                }
            }
        }
        depVM.isLoadingDependencies = false
        await downloadMainResourceOnly()
        depVM.showDependenciesSheet = false
    }

    private func downloadMainResourceOnly() async {
        guard let gameInfo = gameInfo else { return }
        let filteredVersions = try? await ModrinthService.fetchProjectVersionsFilter(
            id: project.projectId,
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
        }
    }
}
