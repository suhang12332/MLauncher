//
//  ContentView.swift
//  MLauncher
//
//  Created by su on 2025/6/1.
//

import SwiftUI

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
    var body: some View {
        switch selectedItem {
        case .game(let gameId):
            GameContentView(gameId: gameId)
        case .resource(let type):
            List {
                if let projectId = selectProjectId {
                    ModrinthProjectContentView(projectDetail: $loadedProjectDetail, projectId: projectId)
                } else {
                    CategoryContentView(
                        project: type.rawValue,
                        selectedCategories: $selectedCategories,
                        selectedFeatures: $selectedFeatures,
                        selectedResolutions: $selectedResolutions,
                        selectedPerformanceImpacts: $selectedPerformanceImpact,
                        selectedVersions: $selectedVersions
                    )
                    .id(refreshID)
                    .onChange(of: type) { _, _ in
                        refreshID = UUID()
                    }
                }
            }
            
        }
    }
    
    
}

