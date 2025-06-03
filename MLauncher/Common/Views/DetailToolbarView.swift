import SwiftUI

/// 详情区域工具栏内容
public struct DetailToolbarView: ToolbarContent {
    let selectedItem: SidebarItem
    @State private var searchText = ""
    @EnvironmentObject var playerListViewModel: PlayerListViewModel // Get the shared view model
    @Binding var sortIndex: String
    @Binding var currentPage: Int
    let totalItems: Int
    let itemsPerPage: Int
    @Binding var project: ModrinthProjectDetail?
    @Binding var selectProjectId: String?
    @Binding var selectedTab: Int
    
    // MARK: - Computed Properties
    var totalPages: Int {
        max(1, Int(ceil(Double(totalItems) / Double(itemsPerPage))))
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
                GameContentView(gameId: gameId)
            case .resource:
                if let _ = selectProjectId {
                    ModrinthProjectDetailToolbarView(projectDetail: $project,selectedTab: $selectedTab, onBack: {
                        selectProjectId = nil
                    })
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
