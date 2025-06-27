import SwiftUI

/// 通用侧边栏视图组件
/// 用于显示游戏列表和资源列表的导航
public struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    let games: [String]
    @StateObject private var lang = LanguageManager.shared
    @State private var showingGameForm = false
    @State private var showPlayerAlert = false
    @EnvironmentObject var gameRepository: GameRepository
    @EnvironmentObject var playerListViewModel: PlayerListViewModel
    @State private var searchText: String = ""
    @ObservedObject private var general = GeneralSettingsManager.shared
    
    public init(selectedItem: Binding<SidebarItem>, games: [String]) {
        self._selectedItem = selectedItem
        self.games = games
    }
    
    public var body: some View {
        List(selection: $selectedItem) {
            // 资源部分
            Section(header: Text("sidebar.resources.title".localized())) {
                ForEach(ResourceType.allCases, id: \.self) { type in
                    NavigationLink(value: SidebarItem.resource(type)) {
                        Text(type.localizedName)
                    }
                }
            }
            
            // 游戏部分
            Section(header: Text("sidebar.games.title".localized())) {
                // 支持模糊搜索
                ForEach(filteredGames) { game in
                    NavigationLink(value: SidebarItem.game(game.id)) {
                        HStack(spacing: 6) {
                            if game.gameIcon.hasPrefix("data:image") {
                                // Extract base64 data from the data URL
                                if let base64String = game.gameIcon.split(
                                    separator: ","
                                ).last,
                                    let imageData = Data(
                                        base64Encoded: String(base64String)
                                    ),
                                    let nsImage = NSImage(data: imageData)
                                {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .interpolation(.none)
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 4)
                                        )
                                } else {
                                    Image(systemName: "gamecontroller")
                                        .frame(width: 16, height: 16)
                                }
                            } else {
                                Image(systemName: "gamecontroller")
                                    .frame(width: 16, height: 16)
                            }
                            Text(game.gameName)
                                .lineLimit(1)
                        }
//                        .padding(.leading, 2.5)
                        .tag(game.id)  // Tag with game ID
                    }
                    
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "sidebar.search.games".localized())
        .navigationTitle("app.name".localized())
//        .id(general.selectedLanguage) // 强制视图在语言改变时重新创建
        .safeAreaInset(edge: .bottom) {
            Button(
                action: {
                    if playerListViewModel.currentPlayer == nil {
                        showPlayerAlert = true
                    } else {
                        showingGameForm.toggle()
                    }
                },
                label: {
                    Label(
                        "addgame".localized(),
                        systemImage: "gamecontroller"
                    )
                }
            )
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .listStyle(.sidebar)
        // The sheet to present the form
        .sheet(isPresented: $showingGameForm) {
            // Pass the EnvironmentObject to GameFormView
            GameFormView()
                .environmentObject(gameRepository)
                .environmentObject(playerListViewModel)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.automatic)
        }
        .alert("sidebar.alert.no_player.title".localized(), isPresented: $showPlayerAlert) {
            Button("common.confirm".localized(), role: .cancel) { }
        } message: {
            Text("sidebar.alert.no_player.message".localized())
        }
    }
    
    // 只对游戏名做模糊搜索
    private var filteredGames: [GameVersionInfo] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return gameRepository.games
        }
        let lower = searchText.lowercased()
        return gameRepository.games.filter { $0.gameName.lowercased().contains(lower) }
    }
}
