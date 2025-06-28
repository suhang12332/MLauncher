import SwiftUI

/// 内容区域工具栏内容
public struct ContentToolbarView: ToolbarContent {
    @EnvironmentObject var playerListViewModel: PlayerListViewModel
    @State private var showingAddPlayerAlert = false
    @State private var playerName = ""
    @State private var isPlayerNameValid = false

    public var body: some ToolbarContent {
        ToolbarItemGroup {
            // 显示玩家列表（如有玩家）
            if !playerListViewModel.players.isEmpty {
                PlayerListView()
                Spacer()
            }
            // 添加玩家按钮
            Button(action: {
                playerName = ""
                isPlayerNameValid = false
                showingAddPlayerAlert = true
            }) {
                Label("player.add".localized(), systemImage: "person.badge.plus")
            }
            .help("player.add".localized())
            .alert("alert.add_player.title".localized(), isPresented: $showingAddPlayerAlert) {
                TextField("alert.add_player.placeholder".localized(), text: $playerName)
                    .onChange(of: playerName) { _, newValue in
                        checkPlayerName(newValue)
                    }
                Button("alert.button.cancel".localized(), role: .cancel) {
                    playerName = ""
                    isPlayerNameValid = false
                }
                Button("alert.button.add".localized()) {
                    if playerListViewModel.addPlayer(name: playerName) {
                        Logger.shared.debug("玩家 \(playerName) 添加成功 (通过 ViewModel)。")
                    } else {
                        Logger.shared.debug("添加玩家 \(playerName) 失败 (通过 ViewModel)。")
                    }
                    playerName = ""
                    isPlayerNameValid = false
                }
                .disabled(!isPlayerNameValid)
            } message: {
                Text("alert.add_player.message".localized())
            }
        }
    }

    // 检查玩家名有效性
    private func checkPlayerName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        isPlayerNameValid = !trimmedName.isEmpty && !playerListViewModel.playerExists(name: trimmedName)
    }
}

