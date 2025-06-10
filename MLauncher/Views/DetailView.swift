//
//  DetailView.swift
//  MLauncher
//
//  Created by su on 2025/6/1.
//

import SwiftUI

struct DetailView: View {
    @ObservedObject private var lang = LanguageManager.shared
    let selectedItem: SidebarItem  // 接收选中的侧边栏项目
    @Binding var currentPage: Int
    @Binding var totalItems: Int
    @Binding var sortIndex: String
    @Binding var gameResourcesType: String
    @Binding var selectedVersions: [String]
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpact: [String]
    @Binding var selectedProjectId: String?
    @Binding var loadedProjectDetail: ModrinthProjectDetail?
    @Binding var selectTab:Int
    @Binding var versionCurrentPage: Int
    @Binding var versionTotal: Int
    @Binding var searchText: String
    @EnvironmentObject var gameRepository: GameRepository
    var body: some View {
        switch selectedItem {
        case .game(let gameId):
            if let gameinfo = gameRepository.getGame(by: gameId) {
                List {
                    GameInfoDetailView(game: gameinfo,query: $gameResourcesType,
                                       currentPage: $currentPage,
                                       totalItems: $totalItems,
                                       sortIndex: $sortIndex,
                                       selectedVersions: $selectedVersions,
                                       selectedCategories: $selectedCategories,
                                       selectedFeatures: $selectedFeatures,
                                       selectedResolutions: $selectedResolutions,
                                       selectedPerformanceImpact: $selectedPerformanceImpact,
                                       selectedProjectId: $selectedProjectId,
                                       searchText: $searchText)
                    .padding()
                    
                }.listStyle(.plain)
                
            }
            
        case .resource(let type):
            List {
                if selectedProjectId != nil {
                    if let project = loadedProjectDetail {
                        ModrinthProjectDetailView(selectedTab: $selectTab, projectDetail: project, currentPage: $versionCurrentPage,versionTotal: $versionTotal)
                    } else {
                        EmptyView()
                    }
                } else {
                    ModrinthDetailView(
                        query: type.rawValue,
                        currentPage: $currentPage,
                        totalItems: $totalItems,
                        sortIndex: $sortIndex,
                        selectedVersions: $selectedVersions,
                        selectedCategories: $selectedCategories,
                        selectedFeatures: $selectedFeatures,
                        selectedResolutions: $selectedResolutions,
                        selectedPerformanceImpact: $selectedPerformanceImpact,
                        selectedProjectId: $selectedProjectId,
                        searchText: $searchText
                    )
                    .padding()
                }
                
            }.listStyle(.plain)
            

        }
    }
}
