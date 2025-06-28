//
//  MainView.swift
//  MLauncher
//
//  Created by su on 2025/5/30.
//

import SwiftUI

struct MainView: View {
    // MARK: - State & Environment
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var selectedItem: SidebarItem = .resource(.mod)
    @ObservedObject private var general = GeneralSettingsManager.shared
    @EnvironmentObject var gameRepository: GameRepository

    // MARK: - Resource/Project State
    @State private var currentPage: Int = 1
    @State private var totalItems: Int = 0
    @State private var sortIndex: String = "relevance"
    @State private var selectedVersions: [String] = []
    @State private var selectedLicenses: [String] = []
    @State private var selectedCategories: [String] = []
    @State private var selectedFeatures: [String] = []
    @State private var selectedResolutions: [String] = []
    @State private var selectedPerformanceImpact: [String] = []
    @State private var selectedLoaders: [String] = []
    @State private var selectedProjectId: String?
    @State private var loadedProjectDetail: ModrinthProjectDetail?
    @State private var selectedTab = 0

    // MARK: - Version/Detail State
    @State private var versionCurrentPage: Int = 1
    @State private var versionTotal: Int = 0
    @State private var gameResourcesType = "mod"
    @State private var gameResourcesLocation = false  // false = local, true = server
    @State private var gameId: String?

    // MARK: - Body
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 侧边栏
            SidebarView(selectedItem: $selectedItem)
                .navigationSplitViewColumnWidth(min: 160, ideal: 160, max: 160)
        } content: {
            ContentView(
                selectedItem: selectedItem,
                selectedVersions: $selectedVersions,
                selectedLicenses: $selectedLicenses,
                selectedCategories: $selectedCategories,
                selectedFeatures: $selectedFeatures,
                selectedResolutions: $selectedResolutions,
                selectedPerformanceImpact: $selectedPerformanceImpact,
                selectProjectId: $selectedProjectId,
                loadedProjectDetail: $loadedProjectDetail,
                gameResourcesType: $gameResourcesType,
                selectedLoaders: $selectedLoaders,
                gameResourcesLocation: $gameResourcesLocation,
                gameId: $gameId
            )
            .toolbar { ContentToolbarView() }
            .navigationSplitViewColumnWidth(min: 235, ideal: 240, max: 250)
        } detail: {
            DetailView(
                selectedItem: $selectedItem,
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
                gameResourcesLocation: $gameResourcesLocation,
                selectedLoader: $selectedLoaders
            )
            .toolbar {
                DetailToolbarView(
                    selectedItem: $selectedItem,
                    sortIndex: $sortIndex,
                    gameResourcesType: $gameResourcesType,
                    resourceType: $gameResourcesLocation,
                    currentPage: $currentPage,
                    versionCurrentPage: $versionCurrentPage,
                    versionTotal: $versionTotal,
                    totalItems: totalItems,
                    project: $loadedProjectDetail,
                    selectProjectId: $selectedProjectId,
                    selectedTab: $selectedTab,
                    gameId: $gameId
                )
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            handleSidebarItemChange(from: oldValue, to: newValue)
        }
        .onChange(of: selectedProjectId) { _, _ in
            loadedProjectDetail = nil
        }
        .preferredColorScheme(general.themeMode.colorScheme)
    }

    // MARK: - Sidebar Item Change Handlers
    private func handleSidebarItemChange(from oldValue: SidebarItem, to newValue: SidebarItem) {
        switch (oldValue, newValue) {
        case (.resource, .game(let id)):
            handleResourceToGameTransition(gameId: id)
        case (.game, .resource):
            resetToResourceDefaults()
        case (.game(let oldId), .game(let newId)):
            handleGameToGameTransition(from: oldId, to: newId)
        case (.resource, .resource):
            resetToResourceDefaults()
        }
    }

    // MARK: - Transition Helpers
    private func handleResourceToGameTransition(gameId: String) {
        gameResourcesLocation = false
        let game = gameRepository.getGame(by: gameId)
        gameResourcesType = game?.modLoader.lowercased() == "vanilla" ? "datapack" : "mod"
        self.gameId = gameId
        selectedProjectId = nil
    }

    private func handleGameToGameTransition(from oldId: String, to newId: String) {
        gameResourcesLocation = false
        let game = gameRepository.getGame(by: newId)
        gameResourcesType = game?.modLoader.lowercased() == "vanilla" ? "datapack" : "mod"
        gameId = newId
    }

    // MARK: - Resource Reset
    private func resetToResourceDefaults() {
        gameResourcesLocation = true  // true = server mode
        sortIndex = "relevance"
        if case .resource(let resourceType) = selectedItem {
            gameResourcesType = resourceType.rawValue
        }
        currentPage = 1
        totalItems = 0
        selectedVersions.removeAll()
        selectedLicenses.removeAll()
        selectedCategories.removeAll()
        selectedFeatures.removeAll()
        selectedResolutions.removeAll()
        selectedPerformanceImpact.removeAll()
        selectedLoaders.removeAll()
        loadedProjectDetail = nil
        selectedTab = 0
        versionCurrentPage = 1
        versionTotal = 0
        selectedProjectId = nil
        gameId = nil
    }
}

