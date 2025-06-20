//
//  GameInfoDetailView.swift
//  MLauncher
//
//  Created by su on 2025/6/2.
//

import SwiftUI


// MARK: - Views
struct GameInfoDetailView: View {
    let game: GameVersionInfo
    
    @Binding var query: String
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
    @Binding var selectedLoaders: [String]
    @Binding var gameType: String

    @State private var searchTextForResource: String = ""
    
    var body: some View {
        VStack {
            HStack(spacing: 16) { // Added spacing back as per original design
                // Game Icon
                if let nsImage = imageFromBase64(game.gameIcon) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 72, height: 72)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                } else {
                    // Fallback to system icon if decoding fails (e.g., empty string, invalid Base64)
                    Image(systemName: "cube.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .padding(6)
                        .foregroundColor(.gray)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.gameName)
                        .font(.title)
                        .bold()
                    
                    HStack(spacing: 8) {
                        Label(game.gameVersion, systemImage: "gamecontroller.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Label(game.modLoader, systemImage: "gamecontroller.fill")
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
                        Image(systemName: "trash.fill")
                            .padding(.vertical,6)
                            .padding(.horizontal,10)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                    }
                    .buttonStyle(.plain)
                    
                }
            }
            
            Divider()
                .padding(.top,4)
            if gameType == "local" {
                let filteredResources = game.resources.filter { res in
                    res.type == query && (searchTextForResource.isEmpty || res.title.localizedCaseInsensitiveContains(searchTextForResource))
                }
                VStack {
                    ForEach(filteredResources, id: \.projectId) { mod in
                        ModrinthDetailCardView(
                            project: mod,
                            selectedVersions: [game.gameVersion],
                            selectedLoaders: [game.modLoader],
                            gameInfo: game,
                            query: query
                        )
                        .padding(.vertical, ModrinthConstants.UI.verticalPadding)
                        .listRowInsets(
                            EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                        )
                        .onTapGesture {
                            selectedProjectId = mod.projectId
                        }
                    }
                }
                .searchable(text: $searchTextForResource, placement: .automatic, prompt: "搜索资源名称")
            } else {
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
                    searchText: $searchText,
                    selectedLoader: $selectedLoaders,
                    gameInfo: game
                ).id(query)
            }
            
        }
        // 3. 监听 gameResourcesType
        .onChange(of: query) { _,_ in
            selectedVersions = [game.gameVersion]
            Logger.shared.info(selectedLoaders)
            sortIndex = "relevance"
        }
        
        // 4. 监听 gameResourcesLocation
        .onChange(of: gameType) { _,_ in
            selectedVersions = [game.gameVersion]
            Logger.shared.info(selectedLoaders)
            currentPage = 1
            totalItems = 0
            sortIndex = "relevance"
        }
    }
    
    // MARK: - Base64 图片解码工具
    func imageFromBase64(_ base64: String) -> NSImage? {
        if base64.hasPrefix("data:image") {
            if let base64String = base64.split(separator: ",").last,
               let imageData = Data(base64Encoded: String(base64String)),
               let nsImage = NSImage(data: imageData) {
                return nsImage
            }
        } else if let imageData = Data(base64Encoded: base64),
                  let nsImage = NSImage(data: imageData) {
            return nsImage
        }
        return nil
    }
}




