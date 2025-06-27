import SwiftUI
import Foundation
import os

// 新增依赖管理ViewModel，持久化依赖相关状态
class DependencySheetViewModel: ObservableObject {
    @Published var missingDependencies: [ModrinthProject] = []
    @Published var isLoadingDependencies: Bool = true
    @Published var showDependenciesSheet: Bool = false
    @Published var dependencyDownloadStates: [String: ResourceDownloadState] = [:] // projectId: state

    func resetDownloadStates() {
        for dep in missingDependencies {
            dependencyDownloadStates[dep.projectId] = .idle
        }
    }
}

// 1. 下载状态定义
enum ResourceDownloadState {
    case idle
    case downloading
    case success
    case failed
}

struct AddOrDeleteResourceButton: View {
    var project: ModrinthProject
    let selectedVersions: [String]
    let selectedLoaders: [String]
    let gameInfo: GameVersionInfo?
    let query: String
    let type: String
    @EnvironmentObject private var gameRepository: GameRepository
    @State private var addButtonState: ModrinthDetailCardView.AddButtonState = .idle
    @State private var showDeleteAlert = false
    @ObservedObject private var gameSettings = GameSettingsManager.shared
    @StateObject private var depVM = DependencySheetViewModel()
    
    var body: some View {
        Button(action: {
            switch addButtonState {
            case .idle:
                if gameSettings.autoDownloadDependencies {
                    addButtonState = .loading
                    Task {
                        await downloadWithDependencies()
                    }
                } else {
                    //
                }
            case .installed:
                if type == "local" {
                    showDeleteAlert = true
                }
            default:
                break
            }
        }) {
            switch addButtonState {
            case .idle:
                Text("resource.add".localized())
            case .loading:
                ProgressView()
            case .installed:
                Text((type == "local" ? "common.delete" : "resource.installed").localized())
            }
        }
        .buttonStyle(.borderedProminent)
        .font(.caption2)
        .controlSize(.small)
        .disabled(addButtonState == .loading || (addButtonState == .installed && type != "local"))
        .onAppear {
            if let gameInfo = gameInfo,
               let latestGame = gameRepository.getGame(by: gameInfo.id),
               latestGame.resources.contains(where: { $0.id == project.projectId }) {
                addButtonState = .installed
            }
        }
        .onReceive(gameRepository.objectWillChange) { _ in
            if let gameInfo = gameInfo,
               let latestGame = gameRepository.getGame(by: gameInfo.id) {
                if latestGame.resources.contains(where: { $0.id == project.projectId }) {
                    addButtonState = .installed
                } else if addButtonState == .installed {
                    // 只有在原本是已安装，且资源被移除时才变成 idle
                    addButtonState = .idle
                }
                // 其他情况下不动
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("common.delete".localized()),
                message: Text(String(format: "resource.delete.confirm".localized(), project.title)),
                primaryButton: .destructive(Text("common.delete".localized())) {
                    removeResource()
                },
                secondaryButton: .cancel()
            )
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
    
    // 自动依赖下载逻辑
    private func downloadWithDependencies() async {
        // 下载所有直接依赖（不递归）
        guard let gameInfo = gameInfo else { return }
        var actuallyDownloaded: [ModrinthProjectDetail] = []
        await ModrinthDependencyDownloader.downloadAllDependenciesRecursive(
            for: project.projectId,
            gameInfo: gameInfo,
            query: query,
            gameRepository: gameRepository,
            actuallyDownloaded: &actuallyDownloaded
        )
        // 主动检查并切换按钮状态
        await MainActor.run {
            if let latestGame = gameRepository.getGame(by: gameInfo.id),
               latestGame.resources.contains(where: { $0.id == project.projectId }) {
                addButtonState = .installed
            } else {
                addButtonState = .idle
            }
        }
    }
}
