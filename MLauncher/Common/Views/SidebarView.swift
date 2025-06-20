import SwiftUI

/// 通用侧边栏视图组件
/// 用于显示游戏列表和资源列表的导航
public struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    let games: [String]
    @StateObject private var lang = LanguageManager.shared
    @State private var showingGameForm = false
    @EnvironmentObject var gameRepository: GameRepository
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
                // Iterate over the games from GameRepository
                ForEach(gameRepository.games) { game in
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
        .navigationTitle("app.name".localized())
        .id(lang.selectedLanguage) // 强制视图在语言改变时重新创建    、
        .safeAreaInset(edge: .bottom) {
            Button(
                action: {
                    showingGameForm.toggle()
                },
                label: {
                    Label(
                        NSLocalizedString("addgame", comment: "添加游戏"),
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
            GameFormView().environmentObject(gameRepository)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.automatic)
        }
    }
}
