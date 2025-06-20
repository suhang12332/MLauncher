import SwiftUI

struct ModrinthDetailCardView: View {
    // MARK: - Properties
    var project: ModrinthProject
    let selectedVersions: [String]
    let selectedLoaders: [String]
    let gameInfo: GameVersionInfo?
    let query: String
    
    @State private var addButtonState: AddButtonState = .idle
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
                .id(url)
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
            addButton
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
    
    private var addButton: some View {
        Button(action: {
            guard addButtonState == .idle else { return }
            addButtonState = .loading
            Task {
                do {
                    let filteredVersions = try await ModrinthService.fetchProjectVersionsFilter(
                        id: project.projectId,
                        selectedVersions: selectedVersions,
                        selectedLoaders: selectedLoaders
                    )
                    if let latestVersion = filteredVersions.first,
                       let fileURL = latestVersion.files.first?.url,
                       let gameInfo = gameInfo {
                        _ = try await DownloadManager.downloadResource(
                            for: gameInfo,
                            urlString: fileURL,
                            resourceType: query
                        )
                        let resourceToAdd = ModrinthProject(
                            projectId: project.projectId,
                            projectType: project.projectType,
                            slug: project.slug,
                            author: project.author,
                            title: project.title,
                            description: project.description,
                            categories: project.categories,
                            displayCategories: project.displayCategories,
                            versions: project.versions,
                            downloads: project.downloads,
                            follows: project.follows,
                            iconUrl: project.iconUrl,
                            dateCreated: project.dateCreated,
                            dateModified: project.dateModified,
                            latestVersion: project.latestVersion,
                            license: project.license,
                            clientSide: project.clientSide,
                            serverSide: project.serverSide,
                            gallery: project.gallery,
                            featuredGallery: project.featuredGallery,
                            type: query,
                            color: project.color
                        )
                        _ = gameRepository.addResource(id: gameInfo.id, resource: resourceToAdd)
                        addButtonState = .installed
                    } else {
                        addButtonState = .idle
                    }
                } catch {
                    print("Error fetching versions or downloading: \(error)")
                    addButtonState = .idle
                }
            }
        }) {
            switch addButtonState {
            case .idle:
                Text("+ Add")
            case .loading:
                ProgressView()
            case .installed:
                Text("已安装")
            }
        }
        .buttonStyle(.borderedProminent)
        .font(.caption2)
        .controlSize(.small)
        .disabled(addButtonState != .idle)
        .onAppear {
            if let gameInfo = gameInfo, gameInfo.resources.contains(where: { $0.projectId == project.projectId }) {
                addButtonState = .installed
            }
        }
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
