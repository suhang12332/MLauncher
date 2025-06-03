import SwiftUI

// MARK: - Constants
private enum CategorySectionConstants {
    static let maxHeight: CGFloat = 235
    static let verticalPadding: CGFloat = 4
    static let headerBottomPadding: CGFloat = 4
    static let placeholderCount: Int = 5
}

// MARK: - Category Section View
struct CategorySectionView: View {
    // MARK: - Properties
    let title: String
    let items: [FilterItem]
    @Binding var selectedItems: [String]
    let isLoading: Bool
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            if isLoading {
                loadingPlaceholder
            } else {
                contentView
            }
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        HStack(alignment: .center) {
            headerTitle
            Spacer()
            clearButton
        }
        .padding(.bottom, CategorySectionConstants.headerBottomPadding)
    }
    
    private var headerTitle: some View {
        LabeledContent {
            if !selectedItems.isEmpty {
                Text("\(selectedItems.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        } label: {
            Text(title.localized())
                .font(.headline)
        }
    }
    
    @ViewBuilder
    private var clearButton: some View {
        if !selectedItems.isEmpty {
            Button(action: clearSelection) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("filter.clear".localized())
        }
    }
    
    private var loadingPlaceholder: some View {
        ScrollView {
            FlowLayout {
                ForEach(0..<CategorySectionConstants.placeholderCount, id: \.self) { _ in
                    FilterChip(title: "common.loading".localized(), isSelected: false, action: {})
                        .redacted(reason: .placeholder)
                }
            }
        }
        .frame(maxHeight: CategorySectionConstants.maxHeight)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, CategorySectionConstants.verticalPadding)
    }
    
    private var contentView: some View {
        ScrollView {
            FlowLayout {
                ForEach(items) { item in
                    FilterChip(
                        title: item.name,
                        isSelected: selectedItems.contains(item.id),
                        action: { toggleSelection(for: item.id) }
                    )
                }
            }
        }
        .frame(maxHeight: CategorySectionConstants.maxHeight)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, CategorySectionConstants.verticalPadding)
    }
    
    // MARK: - Actions
    private func clearSelection() {
        selectedItems.removeAll()
    }
    
    private func toggleSelection(for id: String) {
        if selectedItems.contains(id) {
            selectedItems.removeAll { $0 == id }
        } else {
            selectedItems.append(id)
        }
    }
} 
