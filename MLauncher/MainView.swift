//
//  MainView.swift
//  MLauncher
//
//  Created by su on 2025/5/30.
//

import SwiftUI

struct MainView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var selectedItem: SidebarItem = SidebarItem.resource(.mod)
    @State private var games: [String] = []  // 这里应该从数据源获取游戏列表
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    // 分页相关
    @State private var currentPage: Int = 1
    @State private var totalItems: Int = 0
    @State private var sortIndex: String = "relevance"
    @State private var selectedVersions: [String] = []
    @State private var selectedLicenses: [String] = []
    @State private var selectedCategories: [String] = []
    @State private var selectedFeatures: [String] = []
    @State private var selectedResolutions: [String] = []
    @State private var selectedPerformanceImpact: [String] = []
    @State private var selectedProjectId: String?
    @State private var loadedProjectDetail: ModrinthProjectDetail? = nil
    @State private var selectedTab = 0

    @State private var versionCurrentPage: Int = 1
    @State private var versionTotal: Int = 0
    @State private var gameResourcesType = "mod"
    @State private var searchText: String = ""
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 侧边栏
            SidebarView(selectedItem: $selectedItem, games: games)
                .navigationSplitViewColumnWidth(min: 160, ideal: 160, max: 160)
        } content: {
            // 内容区，使用新的 ContentView
            ContentView(
                selectedItem: selectedItem,
                selectedVersions: $selectedVersions,
                selectedLicenses: $selectedLicenses,
                selectedCategories: $selectedCategories,
                selectedFeatures: $selectedFeatures,
                selectedResolutions: $selectedResolutions,
                selectedPerformanceImpact: $selectedPerformanceImpact,
                selectProjectId: $selectedProjectId,
                loadedProjectDetail: $loadedProjectDetail
            )
            .toolbar {
                ContentToolbarView()
            }.navigationSplitViewColumnWidth(min: 235, ideal: 240, max: .infinity)
        } detail: {
            DetailView(
                selectedItem: selectedItem,
                currentPage: $currentPage,
                totalItems: $totalItems,
                sortIndex: $sortIndex,
                gameResourcesType: $gameResourcesType,
                selectedVersions: $selectedVersions,
                selectedCategories: $selectedCategories,
                selectedFeatures: $selectedFeatures,
                selectedResolutions: $selectedResolutions,
                selectedPerformanceImpact: $selectedPerformanceImpact,
                selectedProjectId: $selectedProjectId,
                loadedProjectDetail: $loadedProjectDetail,
                selectTab: $selectedTab,
                versionCurrentPage: $versionCurrentPage,
                versionTotal: $versionTotal,
                searchText: $searchText
            )
            .toolbar {
                
                DetailToolbarView(
                    selectedItem: selectedItem,
                    sortIndex: $sortIndex,
                    gameResourcesType: $gameResourcesType,
                    currentPage: $currentPage,
                    versionCurrentPage: $versionCurrentPage,
                    versionTotal: $versionTotal,
                    totalItems: totalItems,
                    project: $loadedProjectDetail,
                    selectProjectId: $selectedProjectId,
                    selectedTab: $selectedTab,
                    searchText: $searchText
                )
            }

        }
        .onChange(of: selectedItem) { _, newValue in
            if case .resource(_) = newValue {
                sortIndex = "relevance"
                gameResourcesType = "mod"
                currentPage = 1
                totalItems = 0
                selectedVersions = []
                selectedLicenses = []
                selectedCategories = []
                selectedFeatures = []
                selectedResolutions = []
                selectedPerformanceImpact = []
                selectedProjectId = nil
                // Reset loaded project detail when selected item changes
                loadedProjectDetail = nil
                selectedTab = 0
                versionCurrentPage = 1
                versionTotal = 0
                searchText = ""
            }
        }
        .onChange(of: selectedProjectId) { _, _ in
            // Reset loaded project detail when selected project changes
            loadedProjectDetail = nil
        }
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    MainView()
}
