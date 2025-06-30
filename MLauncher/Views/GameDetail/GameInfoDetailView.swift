//
//  GameInfoDetailView.swift
//  MLauncher
//
//  Created by su on 2025/6/2.
//

import SwiftUI
import AppKit

// MARK: - Window Delegate
class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()
    private var windows: [NSWindow] = []
    
    private override init() {
        super.init()
    }
    
    func addWindow(_ window: NSWindow) {
        windows.append(window)
        window.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            windows.removeAll { $0 == window }
        }
    }
}

// MARK: - Views
struct GameInfoDetailView: View {
    let game: GameVersionInfo
    
    @Binding var query: String
    @Binding var currentPage: Int
    @Binding var totalItems: Int
    @Binding var sortIndex: String
    @Binding var selectedVersions: [String]
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpact: [String]
    @Binding var selectedProjectId: String?
    @Binding var selectedLoaders: [String]
    @Binding var gameType: Bool  // false = local, true = server
    @EnvironmentObject var gameRepository: GameRepository
    @State private var searchTextForResource = ""
    @State private var showDeleteAlert = false
    @Binding var selectedItem: SidebarItem
    
    var body: some View {
        return VStack {
            headerView
            Divider().padding(.top, 4)
            if gameType {
                ModrinthDetailView(
                    query: query,
                    currentPage: $currentPage,
                    totalItems: $totalItems,
                    sortIndex: $sortIndex,
                    selectedVersions: $selectedVersions,
                    selectedCategories: $selectedCategories,
                    selectedFeatures: $selectedFeatures,
                    selectedResolutions: $selectedResolutions,
                    selectedPerformanceImpact: $selectedPerformanceImpact,
                    selectedProjectId: $selectedProjectId,
                    selectedLoader: $selectedLoaders,
                    gameInfo: game,
                    selectedItem: $selectedItem,
                    gameType: $gameType
                )
            } else {
                localResourceList
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 16) {
            gameIcon
            VStack(alignment: .leading, spacing: 4) {
                Text(game.gameName)
                    .font(.title)
                    .bold()
                HStack(spacing: 8) {
                    Label(game.gameVersion, systemImage: "gamecontroller.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Label(game.modLoader, systemImage: "puzzlepiece.extension.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Label(game.lastPlayed.formatted(.relative(presentation: .named)), systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            deleteButton
        }
    }

    private var gameIcon: some View {
        Group {
            if let nsImage = CommonUtil.imageFromBase64(game.gameIcon) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 72, height: 72)
                    .cornerRadius(12)
                } else {
                    Image(systemName: "cube.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .padding(6)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
        }
    }

    private var deleteButton: some View {
        HStack(spacing: 12) {
            Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash.fill")
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(
                            title: Text("delete.title".localized()),
                            message: Text(String(format: "delete.game.confirm".localized(), game.gameName)),
                    primaryButton: .destructive(Text("common.delete".localized())) { deleteGameAndProfile() },
                            secondaryButton: .cancel(Text("common.cancel".localized()))
                        )
                    }
                }
            }
            
    // MARK: - Local Resource List
    private var localResourceList: some View {
        let filteredResources = game.resources.filter { res in
            res.type == query && (searchTextForResource.isEmpty || res.title.localizedCaseInsensitiveContains(searchTextForResource))
        }.map { ModrinthProject.from(detail: $0) }
        return VStack {
            ForEach(filteredResources, id: \.projectId) { mod in
                ModrinthDetailCardView(
                    project: mod,
                    selectedVersions: [game.gameVersion],
                    selectedLoaders: [game.modLoader],
                    gameInfo: game,
                    query: query,
                    type: gameType,
                    selectedItem: $selectedItem
                )
                .padding(.vertical, ModrinthConstants.UI.verticalPadding)
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .onTapGesture {
                    selectedProjectId = mod.projectId
                    if let type = ResourceType(rawValue: query) {
                        selectedItem = .resource(type)
                    }
                }
            }
        }
        .searchable(text: $searchTextForResource, placement: .automatic, prompt: "搜索资源名称")
    }
    
    // MARK: - 删除游戏及其文件夹
    private func deleteGameAndProfile() {
        gameRepository.deleteGame(id: game.id)
        if let profileDir = AppPaths.profileDirectory(gameName: game.gameName) {
            try? FileManager.default.removeItem(at: profileDir)
        }
        if let firstGame = gameRepository.games.first {
            selectedItem = .game(firstGame.id)
        } else {
            selectedItem = .resource(.mod)
        }
    }

    private var filteredResources: [ModrinthProjectDetail] {
        if searchTextForResource.isEmpty {
            return game.resources
        } else {
            return game.resources.filter { $0.title.localizedCaseInsensitiveContains(searchTextForResource) }
        }
    }
}




