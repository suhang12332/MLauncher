//
//  GameInfoDetailView.swift
//  MLauncher
//
//  Created by su on 2025/6/2.
//

import SwiftUI
import Foundation // Required for Date and Data
import MLauncher // Assuming GameVersionInfo and ModrinthDetailView are in the main MLauncher module

// MARK: - Models
// Assuming GameVersionInfo is defined elsewhere and imported, e.g., from MLauncher/Models/GameVersionInfo.swift
// If it's not globally available, uncomment and use this local definition
/*
struct GameVersionInfo: Codable, Equatable, Identifiable {
    let id: String
    let gameName: String
    let gameIcon: String // Base64 encoded string for the icon
    let gameVersion: String
    let modLoader: String
    let isUserAdded: Bool
    let createdAt: Date
    var lastPlayed: Date
    var isRunning: Bool
    var javaPath: String
    var jvmArguments: String
    var launchCommand: String
    var runningMemorySize: Int

    init(
        id: UUID = UUID(),
        gameName: String,
        gameIcon: String,
        gameVersion: String,
        modLoader: String,
        isUserAdded: Bool,
        createdAt: Date = Date(),
        lastPlayed: Date = Date(),
        isRunning: Bool = false,
        javaPath: String = "",
        jvmArguments: String = "",
        launchCommand: String = "",
        runningMemorySize: Int = 2048
    ) {
        self.id = id.uuidString
        self.gameName = gameName
        self.gameIcon = gameIcon
        self.gameVersion = gameVersion
        self.modLoader = modLoader
        self.isUserAdded = isUserAdded
        self.createdAt = createdAt
        self.lastPlayed = lastPlayed
        self.isRunning = isRunning
        self.javaPath = javaPath
        self.jvmArguments = jvmArguments
        self.launchCommand = launchCommand
        self.runningMemorySize = runningMemorySize
    }
}
*/

// MARK: - Views
struct GameInfoDetailView: View {
    let game: GameVersionInfo
    @State var query: String
    @Binding var currentPage: Int
    @Binding var totalItems: Int
    @Binding var sortIndex: String
    @Binding var selectedVersions: [String]
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpact: [String]
    @Binding var selectedProjectId: String?
    @Binding var searchText: String
    
    var body: some View {
        VStack {
            HStack(spacing: 16) { // Added spacing back as per original design
                // Game Icon
                // game.gameIcon is String (non-optional), so direct decoding is attempted.
                if let imageData = Data(base64Encoded: game.gameIcon), let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    // Fallback to system icon if decoding fails (e.g., empty string, invalid Base64)
                    Image(systemName: "cube.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(game.gameName)
                        .font(.headline)
                        .bold()

                    HStack(spacing: 8) {
                        Label(game.gameVersion, systemImage: "gamecontroller.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // game.lastPlayed is Date (non-optional)
                        Label(game.lastPlayed.formattedDate(), systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()

                // Actions
                HStack(spacing: 12) { // Added spacing back as per original design
                    Button(action: {
                        // Action for Play
                        print("Play button tapped for \(game.gameName)")
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        // Action for Settings
                        print("Settings button tapped for \(game.gameName)")
                    }) {
                        Image(systemName: "gearshape.fill")
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        // Action for More Options
                        print("More options button tapped for \(game.gameName)")
                    }) {
                        Image(systemName: "ellipsis")
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding() // Re-added padding for the HStack content
            .background(Color.white) // Re-added background
            .cornerRadius(12) // Re-added cornerRadius
            .shadow(radius: 2) // Re-added shadow
            
            // ModrinthDetailView integration
            ModrinthDetailView(
                query: query,
                currentPage: $currentPage,
                totalItems: $totalItems,
                sortIndex: $sortIndex,
                selectedVersions: $selectedVersions,
                selectedCategories: $selectedCategories,
                selectedFeatures: $selectedFeatures,
                selectedResolutions: $selectedResolutions,
                selectedPerformanceImpact: $selectedPerformanceImpact,
                selectedProjectId: $selectedProjectId,
                searchText: $searchText
            )
        }
        .padding() // Outer VStack padding, ensures ModrinthDetailView also has padding
    }
}

// MARK: - Previews
struct GameInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GameInfoDetailView(
                game: GameVersionInfo(
                    id: UUID().uuidString,
                    gameName: "1.21.1-fabric",
                    gameIcon: "", // Empty string for no icon, or a valid Base64 string
                    gameVersion: "Fabric 1.21.1",
                    modLoader: "Fabric",
                    isUserAdded: false,
                    createdAt: Date(),
                    lastPlayed: Date()
                ),
                query: "minecraft", // Example query
                currentPage: .constant(1),
                totalItems: .constant(0),
                sortIndex: .constant("relevance"),
                selectedVersions: .constant([]),
                selectedCategories: .constant([]),
                selectedFeatures: .constant([]),
                selectedResolutions: .constant([]),
                selectedPerformanceImpact: .constant([]),
                selectedProjectId: .constant(nil),
                searchText: .constant("")
            )
            .previewLayout(.sizeThatFits)
            .padding()

            // Example with a simulated Base64 icon and a specific last played date
            let sampleBase64Icon = "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==" // A tiny transparent square

            GameInfoDetailView(
                game: GameVersionInfo(
                    id: UUID().uuidString,
                    gameName: "My Custom Game",
                    gameIcon: sampleBase64Icon,
                    gameVersion: "Forge 1.19.2",
                    modLoader: "Forge",
                    isUserAdded: true,
                    createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
                    lastPlayed: Date().addingTimeInterval(-3600 * 2) // 2 hours ago
                ),
                query: "mods", // Example query
                currentPage: .constant(1),
                totalItems: .constant(0),
                sortIndex: .constant("downloads"),
                selectedVersions: .constant(["1.19.2"]),
                selectedCategories: .constant([]),
                selectedFeatures: .constant([]),
                selectedResolutions: .constant([]),
                selectedPerformanceImpact: .constant([]),
                selectedProjectId: .constant(nil),
                searchText: .constant("")
            )
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}

// MARK: - Extensions
extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., "Jun 2, 2025"
        formatter.timeStyle = .short // e.g., "3:30 PM"
        return formatter.string(from: self)
    }
}




