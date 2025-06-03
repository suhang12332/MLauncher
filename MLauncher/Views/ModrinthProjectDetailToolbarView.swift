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
        Button(action: onBack) {
            Image(systemName: "chevron.left")
        }
        Picker("view.mode.title".localized(), selection: $selectedTab) {
            Label("view.mode.details".localized(), systemImage: "doc.text").tag(0)
            Label("view.mode.downloads".localized(), systemImage: "arrow.down.square").tag(1)
        }
        .pickerStyle(.segmented)
        .background(.clear)
    }

}
