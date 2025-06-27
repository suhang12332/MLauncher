import SwiftUI
import Foundation

struct ModrinthDetailCardView: View {
    // MARK: - Properties
    var project: ModrinthProject
    let selectedVersions: [String]
    let selectedLoaders: [String]
    let gameInfo: GameVersionInfo?
    let query: String
    let type: String
    
    @State private var addButtonState: AddButtonState = .idle
    @State private var showDeleteAlert = false
    
    enum AddButtonState {
        case idle
        case loading
        case installed
    }
    @EnvironmentObject private var gameRepository: GameRepository
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: ModrinthConstants.UI.contentSpacing) {
            iconView
            VStack(alignment: .leading, spacing: ModrinthConstants.UI.spacing) {
                titleView
                descriptionView
                tagsView
            }
            Spacer(minLength: 8)
            infoView
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - View Components
    private var iconView: some View {
        Group {
            if let iconUrl = project.iconUrl, let url = URL(string: iconUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.2)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.gray.opacity(0.2)
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: ModrinthConstants.UI.iconSize, height: ModrinthConstants.UI.iconSize)
                .cornerRadius(ModrinthConstants.UI.cornerRadius)
                .clipped()
            } else {
                Color.gray.opacity(0.2)
                    .frame(
                        width: ModrinthConstants.UI.iconSize,
                        height: ModrinthConstants.UI.iconSize
                    )
                    .cornerRadius(ModrinthConstants.UI.cornerRadius)
            }
        }
    }
    
    private var titleView: some View {
        HStack(spacing: 4) {
            Text(project.title)
                .font(.headline)
                .lineLimit(1)
            Text("by \(project.author)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
    
    private var descriptionView: some View {
        Text(project.description)
            .font(.subheadline)
            .lineLimit(ModrinthConstants.UI.descriptionLineLimit)
            .foregroundColor(.secondary)
    }
    
    private var tagsView: some View {
        HStack(spacing: ModrinthConstants.UI.spacing) {
            ForEach(
                Array(project.displayCategories.prefix(ModrinthConstants.UI.maxTags)),
                id: \.self
            ) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, ModrinthConstants.UI.tagHorizontalPadding)
                    .padding(.vertical, ModrinthConstants.UI.tagVerticalPadding)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(ModrinthConstants.UI.tagCornerRadius)
            }
            if project.displayCategories.count > ModrinthConstants.UI.maxTags {
                Text("+\(project.displayCategories.count - ModrinthConstants.UI.maxTags)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var infoView: some View {
        VStack(alignment: .trailing, spacing: ModrinthConstants.UI.spacing) {
            downloadInfoView
            followerInfoView
            AddOrDeleteResourceButton(
                project: project,
                selectedVersions: selectedVersions,
                selectedLoaders: selectedLoaders,
                gameInfo: gameInfo,
                query: query,
                type: type
            )
            .environmentObject(gameRepository)
        }
    }
    
    private var downloadInfoView: some View {
        HStack(spacing: 2) {
            Image(systemName: "arrow.down.circle")
                .imageScale(.small)
            Text("\(Self.formatNumber(project.downloads))")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    
    private var followerInfoView: some View {
        HStack(spacing: 2) {
            Image(systemName: "heart")
                .imageScale(.small)
            Text("\(Self.formatNumber(project.follows))")
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    
    // MARK: - Helper Methods
    static func formatNumber(_ num: Int) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fk", Double(num) / 1_000)
        } else {
            return "\(num)"
        }
    }
}
