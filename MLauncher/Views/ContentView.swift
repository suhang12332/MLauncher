//
//  ContentView.swift
//  MLauncher
//
//  Created by su on 2025/6/1.
//

import SwiftUI
import WebKit
struct ContentView: View {
    let selectedItem: SidebarItem // 接收选中的侧边栏项目
    @Binding var selectedVersions: [String]
    @Binding var selectedLicenses: [String]
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpact: [String]
    @State private var refreshID = UUID()
    @Binding var selectProjectId: String?
    @Binding var loadedProjectDetail: ModrinthProjectDetail?
    @EnvironmentObject var gameRepository: GameRepository
    @Binding var gameResourcesType: String
    @Binding var selectedLoaders: [String]
    @Binding var gameResourcesLocation: String
    @EnvironmentObject var playerListViewModel: PlayerListViewModel
    @Binding var gameId: String?
    var body: some View {
        switch selectedItem {
        case .game(let gameId):
            if let game = gameRepository.getGame(by: gameId) {
                if "local" == gameResourcesLocation {
                    List {
                        HStack {
                            MinecraftSkinRenderView(skinName: playerListViewModel.currentPlayer?.avatarName).frame(minWidth: 200,minHeight: 400)
                        }
                    }
                }else{
            List {
                CategoryContentView(
                    project: gameResourcesType,
                    type: "game",
                    selectedCategories: $selectedCategories,
                    selectedFeatures: $selectedFeatures,
                    selectedResolutions: $selectedResolutions,
                    selectedPerformanceImpacts: $selectedPerformanceImpact,
                    selectedVersions: $selectedVersions,
                            selectedLoaders: $selectedLoaders,
                            gameVersion: game.gameVersion,
                            gameLoader: "Vanilla" == game.modLoader ? nil : game.modLoader
                )
                .id(gameResourcesType)
                    }
                }
            } else {
                Text("game.not_found".localized())
            }
        case .resource(let type):
            List {
                if let projectId = selectProjectId {
                    ModrinthProjectContentView(projectDetail: $loadedProjectDetail, projectId: projectId)
                } else {
                    CategoryContentView(
                        project: type.rawValue,
                        type: "resource",
                        selectedCategories: $selectedCategories,
                        selectedFeatures: $selectedFeatures,
                        selectedResolutions: $selectedResolutions,
                        selectedPerformanceImpacts: $selectedPerformanceImpact,
                        selectedVersions: $selectedVersions,
                        selectedLoaders: $selectedLoaders
                    )
                    .id(refreshID)
                    .onChange(of: type) { _,_ in
                        refreshID = UUID()
                    }
                }
            }
        }
    }
}
