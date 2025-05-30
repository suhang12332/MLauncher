import SwiftUI

/// 通用侧边栏视图组件
/// 用于显示游戏列表和资源列表的导航
public struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    let games: [String]
    @StateObject private var lang = LanguageManager.shared
    
    public init(selectedItem: Binding<SidebarItem?>, games: [String]) {
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
                ForEach(games, id: \.self) { gameId in
                    NavigationLink(value: SidebarItem.game(gameId)) {
                        Text(gameId)
                    }
                }
            }
        }
        .navigationTitle("app.name".localized())
        .id(lang.selectedLanguage) // 强制视图在语言改变时重新创建
    }
}

#Preview {
    NavigationStack {
        SidebarView(
            selectedItem: .constant(nil),
            games: ["minecraft", "terraria"]
        )
    }
} 