import SwiftUI

/// A view that displays a list of players.
struct PlayerListView: View {
    @EnvironmentObject var playerListViewModel: PlayerListViewModel  // Access the shared view model
    @Environment(\.dismiss) var dismiss  // To dismiss the popover
    @State private var playerToDelete: Player? = nil
    @State private var showDeleteAlert = false
    
    @State private var showingPlayerListPopover = false // State variable to control the player list popover
    var body: some View {
        Button(action: {
            showingPlayerListPopover.toggle()
        }) {
            PlayerSelectorLabel(selectedPlayer: playerListViewModel.currentPlayer)
        }
        .buttonStyle(.borderless) // Remove default button border
        .popover(isPresented: $showingPlayerListPopover,arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(playerListViewModel.players) { player in
                    HStack {
                        Button {
                            playerListViewModel.setCurrentPlayer(
                                byID: player.id
                            )
                            dismiss()
                        } label: {
                            PlayerAvatarView(
                                player: player,
                                size: 28,
                                cornerRadius: 7
                            )
                            Text(player.name)
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 8)

                        Button {
                            playerToDelete = player
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "person.badge.minus")
                                .help(
                                    "player.remove".localized()
                                )
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
            .frame(width: 200)
        }
        
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text(
                    "player.remove".localized()
                ),
                message: Text(
                    String(
                        format: "player.remove.confirm".localized(),
                        playerToDelete?.name ?? ""
                    )
                ),
                primaryButton: .destructive(
                    Text("player.remove".localized())
                ) {
                    if let player = playerToDelete {
                        _ = playerListViewModel.deletePlayer(byID: player.id)
                    }
                    playerToDelete = nil
                },
                secondaryButton: .cancel(
                    Text("alert.button.cancel".localized())
                ) {
                    playerToDelete = nil
                }
            )
        }
    }
}

// Optional preview for development
#Preview {
    PlayerListView()
        .environmentObject(PlayerListViewModel())  // Provide a sample view model for preview
}
private struct PlayerSelectorLabel: View {
    let selectedPlayer: Player?

    var body: some View {
        if let selectedPlayer = selectedPlayer {
            HStack(spacing: 6) {
                PlayerAvatarView(
                    player: selectedPlayer,
                    size: 22,
                    cornerRadius: 5
                )
                Text(selectedPlayer.name)
                    .foregroundColor(.primary)
                    .font(.system(size: 13))
            }
        } else {
            EmptyView()
        }
    }
}

// PlayerAvatarView struct definition moved here
private struct PlayerAvatarView: View {
    let player: Player
    var size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        Image(player.avatarName)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .drawingGroup()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
