import SwiftUI

// MARK: - Constants
private enum Constants {
    static let iconSize: CGFloat = 24
    static let cornerRadius: CGFloat = 6
    static let spacing: CGFloat = 8
}

// MARK: - ProjectDetailHeaderView
struct ModrinthProjectDetailToolbarView: View {
    @Binding var projectDetail: ModrinthProjectDetail?
    @Binding var selectedTab: Int
    
    @Binding var versionCurrentPage: Int
    @Binding var versionTotal: Int
    var onBack: () -> Void

    var body: some View {

        if let project = projectDetail {
            Group {
                if let iconUrl = project.iconUrl, let url = URL(string: iconUrl)
                {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.2)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(
                        width: Constants.iconSize,
                        height: Constants.iconSize
                    )
                    .cornerRadius(Constants.cornerRadius)
                    .clipped()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: Constants.iconSize,
                            height: Constants.iconSize
                        )
                        .foregroundColor(.secondary)
                }
            }
            Text(project.title)
                .font(.headline)
        } else {
            ProgressView().controlSize(.small
            )
        }

        Spacer()
        // 文件版本的分页
        if selectedTab == 1 {
            versionPaginationControls
        }

        Button(action: onBack) {
            Image(systemName: "house")
        }
        Picker("view.mode.title".localized(), selection: $selectedTab) {
            Label("view.mode.details".localized(), systemImage: "doc.text").tag(0)
            Label("view.mode.downloads".localized(), systemImage: "arrow.down.circle").tag(1)
        }
        .pickerStyle(.segmented)
        .background(.clear)
    }

    private var versionTotalPages: Int {
        max(1, Int(ceil(Double(versionTotal) / Double(20))))
    }
    private var versionPaginationControls: some View {
        HStack(spacing: 8) {
            // Previous Page Button
            Button(action: { versionCurrentPage -= 1 }) {
                Image(systemName: "chevron.left")
            }
            .disabled(versionCurrentPage <= 1)

            // Page Info
            HStack(spacing: 8) {
                Text("第 \(versionCurrentPage) 页")
                Divider()
                    .frame(height: 16)
                Text("共 \(versionTotalPages) 页")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Next Page Button
            Button(action: { versionCurrentPage += 1 }) {
                Image(systemName: "chevron.right")
            }
            .disabled(versionCurrentPage == versionTotalPages)
        }
    }

}
