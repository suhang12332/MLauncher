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
    @Binding var selectedVersions: [String]
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpact: [String]
    @Binding var selectedProjectId: String?
    @Binding var loadedProjectDetail: ModrinthProjectDetail?
    @Binding var selectTab:Int
    var body: some View {
        switch selectedItem {
        case .game(let gameId):
            GameContentView(gameId: gameId)
        case .resource(let type):
            List {
                if selectedProjectId != nil {
                    if let project = loadedProjectDetail {
                        ModrinthProjectDetailView(
                            selectedTab: $selectTab,
                            projectDetail: project // Pass the binding here
                            
                        )
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
                        selectedProjectId: $selectedProjectId
                    )
                    .listStyle(.plain)
                }
            }
            

        }
    }
}
