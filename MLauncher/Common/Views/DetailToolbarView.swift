import SwiftUI

/// 详情区域工具栏内容
public struct DetailToolbarView: ToolbarContent {
    let selectedItem: SidebarItem
    
    @EnvironmentObject var playerListViewModel: PlayerListViewModel  // Get the shared view model
    @Binding var sortIndex: String
    @Binding var gameResourcesType: String
    @Binding var currentPage: Int

    @Binding var versionCurrentPage: Int
    @Binding var versionTotal: Int

    let totalItems: Int


    @Binding var project: ModrinthProjectDetail?
    @Binding var selectProjectId: String?
    @Binding var selectedTab: Int
    @Binding var searchText: String

    // MARK: - Computed Properties
    var totalPages: Int {
        max(1, Int(ceil(Double(totalItems) / Double(20))))
    }
    // MARK: - Private Methods
    private func handlePageChange(_ increment: Int) {
        let newPage = currentPage + increment
        if newPage >= 1 && newPage <= totalPages {
            currentPage = newPage
        }
    }

    public var body: some ToolbarContent {

        // 根据 selectedItem 定制工具栏内容
        ToolbarItemGroup(placement: .primaryAction) {
            switch selectedItem {
            case .game(let gameId):
                sortMenu
                resourcesMenu
                    
                paginationControls
                
                Spacer()
            case .resource:
                if selectProjectId != nil {
                    ModrinthProjectDetailToolbarView(
                        projectDetail: $project,
                        selectedTab: $selectedTab,
                        versionCurrentPage: $versionCurrentPage,
                        versionTotal: $versionTotal,
                        onBack: {
                            selectProjectId = nil
                        }
                    )
                } else {
                    sortMenu
                    paginationControls
                    Spacer()
                }
            }

        }
    }

    private var currentSortTitle: String {
        "menu.sort.\(sortIndex)".localized()
    }
    private var currentResourceTitle: String {
        "resource.content.type.\(gameResourcesType)".localized()
    }
    
    private var sortMenu: some View {
        Menu {
            ForEach(
                ["relevance", "downloads", "follows", "newest", "updated"],
                id: \.self
            ) { sort in
                Button(
                    "menu.sort.\(sort)".localized()
                ) {
                    sortIndex = sort
                }
            }
        } label: {
            Text(currentSortTitle)
        }
        .help("player.add".localized())
    }
    private var resourcesMenu: some View {
        Menu {
            ForEach(
                ["mod", "datapack", "shader", "resourcepack"],
                id: \.self
            ) { sort in
                Button(
                    "resource.content.type.\(sort)".localized()
                ) {
                    gameResourcesType = sort
                }
            }
        } label: {
            Text(currentResourceTitle)
        }
        .help("player.add".localized())
    }
    private var paginationControls: some View {
        HStack(spacing: 8) {
            // Previous Page Button
            Button(action: { handlePageChange(-1) }) {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPage == 1)

            // Page Info
            HStack(spacing: 8) {
                Text("第 \(currentPage) 页")
                Divider()
                    .frame(height: 16)
                Text("共 \(totalPages) 页")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Next Page Button
            Button(action: { handlePageChange(1) }) {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPage == totalPages)
        }
    }
}
