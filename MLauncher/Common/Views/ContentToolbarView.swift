import SwiftUI

/// 内容区域工具栏内容
public struct ContentToolbarView: ToolbarContent {
    @EnvironmentObject var playerListViewModel: PlayerListViewModel // Get the shared view model
    @State private var showingAddPlayerAlert = false // State variable for the Add Player alert
    
    @State private var playerName = "" // State variable for text field input
    @State private var isPlayerNameValid = false // State variable to track player name validity
    
    
    
    // Removed constants for avatar size and corner radius, now defined in PlayerAvatarView
    // private let avatarSize: CGFloat = 24 // Adjust size as needed
    // private let avatarCornerRadius: CGFloat = 4 // Adjust corner radius as needed
    
    // Removed direct instantiation of PlayerDataManager
    // private let dataManager = PlayerDataManager()

    
    public var body: some ToolbarContent {
        // 根据 selectedItem 定制工具栏内容
        ToolbarItemGroup {
            
            // Button to show the player list popover, only shown if there is a current player
            // Use if let to safely unwrap currentPlayer and get its avatarName
            if !playerListViewModel.players.isEmpty {
                PlayerListView()
                Spacer()
            }
            
            
            Button(action: {
                playerName = "" // Clear text field on opening alert
                isPlayerNameValid = false // Reset validity on opening alert
                showingAddPlayerAlert = true
            }) {
                Label(
                    "player.add".localized(),
                    systemImage: "person.badge.plus"
                )
            }
            .help("player.add".localized())
            .alert("alert.add_player.title".localized(), isPresented: $showingAddPlayerAlert) {
                // Actions (Buttons and TextField)
                TextField("alert.add_player.placeholder".localized(), text: $playerName)
                    .onChange(of: playerName) { _, newValue in
                        checkPlayerName(newValue)
                    }
                
                Button("alert.button.cancel".localized(), role: .cancel) {
                    // Cancel action
                    playerName = "" // Clear text field on cancel
                    isPlayerNameValid = false
                }
                
                Button("alert.button.add".localized()) {
                    // Add action using the shared view model
                    if playerListViewModel.addPlayer(name: playerName) {
                        Logger.shared.debug("玩家 \(playerName) 添加成功 (通过 ViewModel)。")
                        // TODO: Potentially update UI to show the new player
                    } else {
                         Logger.shared.debug("添加玩家 \(playerName) 失败 (通过 ViewModel)。")
                         // TODO: Show an error message to the user
                    }
                    playerName = "" // Clear text field after attempting add
                    isPlayerNameValid = false
                }
                .disabled(!isPlayerNameValid) // Disable button if name is invalid
                
            }message: {
                Text("alert.add_player.message".localized())
            }
            
        }
    }
    
    // Method to check player name validity using the shared view model
    private func checkPlayerName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // Name is valid if it's not empty and doesn't already exist (using ViewModel)
        isPlayerNameValid = !trimmedName.isEmpty && !playerListViewModel.playerExists(name: trimmedName)
    }
    
    
}

