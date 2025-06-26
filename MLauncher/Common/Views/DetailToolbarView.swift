import SwiftUI

/// 详情区域工具栏内容
public struct DetailToolbarView: ToolbarContent {
    @Binding var selectedItem: SidebarItem
    
    @EnvironmentObject var playerListViewModel: PlayerListViewModel  // Get the shared view model
    @Binding var sortIndex: String
    @Binding var gameResourcesType: String
    @Binding var resourceType: String
    @Binding var currentPage: Int

    @Binding var versionCurrentPage: Int
    @Binding var versionTotal: Int
    @EnvironmentObject var gameRepository: GameRepository
    let totalItems: Int

    

    @Binding var project: ModrinthProjectDetail?
    @Binding var selectProjectId: String?
    @Binding var selectedTab: Int
    @Binding var searchText: String
    @Binding var gameId: String?

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

    // 新增：当前选中游戏
    private var currentGame: GameVersionInfo? {
        if case .game(let gameId) = selectedItem {
            return gameRepository.getGame(by: gameId)
        }
        return nil
    }

    public var body: some ToolbarContent {

        // 根据 selectedItem 定制工具栏内容
        ToolbarItemGroup(placement: .primaryAction) {
            switch selectedItem {
            case .game:
                if let game = currentGame {
                    if "local" != resourceType {
                        sortMenu
                    }
                    resourcesMenu
                    resourcesTypeMenu
                    if "local" != resourceType {
                        paginationControls
                    }
                    
                    
                    Spacer()
                  
                    .help("player.add".localized())

                    Button(action: {
                        
                        Task {
                            await MinecraftLaunchCommand(player: playerListViewModel.currentPlayer, game: game, gameRepository: gameRepository).launchGame()
                        }
                    }) {
                        Label(
                            "play.fill".localized(),
                            systemImage: "play.fill"
                        )
                    }
                    .disabled(game.isRunning)
                    Button(action: {
                        
//
                    }) {
                        Label(
                            "play.fill".localized(),
                            systemImage: "folder"
                        )
                    }
                   
//                    Spacer()
                }
                
            case .resource:
                if selectProjectId != nil {
                    ModrinthProjectDetailToolbarView(
                        projectDetail: $project,
                        selectedTab: $selectedTab,
                        versionCurrentPage: $versionCurrentPage,
                        versionTotal: $versionTotal,
                        gameId: $gameId,
                        onBack: {
                            if let id = gameId {
                                selectedItem = .game(id)
                            }else{
                                selectProjectId = nil
                                selectedTab = 0
                            }
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
    
    private var currentResourceTypeTitle: String {
        "resource.content.type.\(resourceType)".localized()
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
            ForEach(resourceTypesForCurrentGame, id: \.self) { sort in
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
    private var resourcesTypeMenu: some View {
        Menu {
            ForEach(
                ["local", "server"],
                id: \.self
            ) { sort in
                Button(
                    "resource.content.type.\(sort)".localized()
                ) {
                    resourceType = sort
                }
            }
        } label: {
            Text(currentResourceTypeTitle)
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
    private var resourceTypesForCurrentGame: [String] {
        var types = ["datapack", "shader", "resourcepack"]
        if let game = currentGame, game.modLoader.lowercased() != "vanilla" {
            types.insert("mod", at: 0)
        }
        return types
    }
}
