//
//  AddOrDeleteResourceButton.swift
//  MLauncher
//
//  Created by su on 2025/6/28.
//

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
    @Published var overallDownloadState: OverallDownloadState = .idle

    enum OverallDownloadState {
        case idle // 初始状态，或全部下载成功后
        case failed // 首次"全部下载"操作中，有任何文件失败
        case retrying // 用户正在重试失败项
    }
    
    var allDependenciesDownloaded: Bool {
        // 当没有依赖时，也认为"所有依赖都已下载"
        if missingDependencies.isEmpty { return true }
        
        // 检查所有列出的依赖项是否都标记为成功
        return missingDependencies.allSatisfy { dependencyDownloadStates[$0.id] == .success }
    }

    func resetDownloadStates() {
        for dep in missingDependencies {
            dependencyDownloadStates[dep.id] = .idle
        }
        overallDownloadState = .idle
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
    @State private var isDownloadingAllDependencies = false
    @Binding var selectedItem: SidebarItem
    var body: some View {
        Button(action: handleButtonAction) {
            buttonLabel
        }
        .buttonStyle(.borderedProminent)
        .tint(.accentColor) // 或 .tint(.primary) 但一般用 accentColor 更美观
        .font(.caption2)
        .controlSize(.small)
        .disabled(addButtonState == .loading || (addButtonState == .installed && type))  // type = true (server mode) disables deletion
        .onAppear(perform: updateButtonState)
        .onReceive(gameRepository.objectWillChange) { _ in updateButtonState() }
        .alert(isPresented: $showDeleteAlert) { deleteAlert }
        .sheet(isPresented: $depVM.showDependenciesSheet) {
            DependencySheetView(
                viewModel: depVM,
                isDownloadingAllDependencies: $isDownloadingAllDependencies,
                onDownloadAll: {
                    if depVM.overallDownloadState == .failed {
                        // 如果是失败后点击"继续"
                        await GameResourceHandler.downloadMainResourceAfterDependencies(
                            project: project,
                            gameInfo: gameInfo,
                            depVM: depVM,
                            query: query,
                            gameRepository: gameRepository,
                            updateButtonState: updateButtonState
                        )
                    } else {
                        // 首次点击"全部下载"
                        await GameResourceHandler.downloadAllDependenciesAndMain(
                            project: project,
                            gameInfo: gameInfo,
                            depVM: depVM,
                            query: query,
                            gameRepository: gameRepository,
                            updateButtonState: updateButtonState
                        )
                    }
                },
                onRetry: { dep in
                    Task {
                        await GameResourceHandler.retryDownloadDependency(
                            dep: dep,
                            gameInfo: gameInfo,
                            depVM: depVM,
                            query: query,
                            gameRepository: gameRepository
                        )
                    }
                }
            )
        }
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
            primaryButton: .destructive(Text("common.delete".localized())) {
                if case .game = selectedItem {
                    GameResourceHandler.performDelete(
                        gameInfo: gameInfo,
                        project: project,
                        gameRepository: gameRepository
                    )
                } else if case .resource = selectedItem {
                    GlobalResourceHandler.performDelete(project: project)
                }
            },
            secondaryButton: .cancel()
        )
    }

    // MARK: - Actions
    @MainActor
    private func handleButtonAction() {
        if case .game = selectedItem {
            switch addButtonState {
            case .idle:
                addButtonState = .loading
                Task {
                    // 仅对 mod 类型检查依赖
                    if project.projectType == "mod" {
                        if gameSettings.autoDownloadDependencies {
                            await GameResourceHandler.downloadWithDependencies(
                                project: project,
                                gameInfo: gameInfo,
                                query: query,
                                gameRepository: gameRepository,
                                updateButtonState: updateButtonState
                            )
                        } else {
                            let hasMissingDeps = await GameResourceHandler.prepareManualDependencies(
                                project: project,
                                gameInfo: gameInfo,
                                depVM: depVM
                            )
                            if hasMissingDeps {
                                depVM.showDependenciesSheet = true
                                addButtonState = .idle // Reset button state for when sheet is dismissed
                            } else {
                                await GameResourceHandler.downloadWithDependencies(
                                    project: project,
                                    gameInfo: gameInfo,
                                    query: query,
                                    gameRepository: gameRepository,
                                    updateButtonState: updateButtonState
                                )
                            }
                        }
                    } else {
                        // 其他类型直接下载
                        await GameResourceHandler.downloadSingleResource(
                            project: project,
                            gameInfo: gameInfo,
                            query: query,
                            gameRepository: gameRepository,
                            updateButtonState: updateButtonState
                        )
                    }
                }
            case .installed:
                if !type {
                    showDeleteAlert = true
                }
            default:
                break
            }
        } else if case .resource = selectedItem {
            switch addButtonState {
            case .idle:
                addButtonState = .loading
                Task {
                    await GlobalResourceHandler.performAdd(
                        project: project,
                        query: query,
                        updateButtonState: updateButtonState
                    )
                }
            case .installed:
                if !type {
                    showDeleteAlert = true
                }
            default:
                break
            }
        }
    }

    private func updateButtonState() {
        if case .game = selectedItem {
            GameResourceHandler.updateButtonState(
                gameInfo: gameInfo,
                project: project,
                gameRepository: gameRepository,
                addButtonState: &addButtonState
            )
        } else if case .resource = selectedItem {
            GlobalResourceHandler.updateButtonState(
                project: project,
                addButtonState: &addButtonState
            )
        }
    }
}
