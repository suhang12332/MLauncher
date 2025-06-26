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
    var isVersionSection: Bool = false // 新增参数，版本分组用
    
    @State private var showOverflowPopover = false
    
    // MARK: - Body
    var body: some View {
        VStack {
            headerView
            if isLoading {
                loadingPlaceholder
            } else {
                contentWithOverflow
            }
        }
    }
    
    // MARK: - Subviews
    private var headerView: some View {
        let (_, overflowItems) = computeVisibleAndOverflowItems()
        return HStack {
            headerTitle
            if !overflowItems.isEmpty {
                Button(action: { showOverflowPopover = true }) {
                    Text("+\(overflowItems.count)")
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showOverflowPopover, arrowEdge: .leading) {
                    VStack(alignment: .leading, spacing: 0) {
                        if isLoading {
                            loadingPlaceholder
                        } else if isVersionSection {
                            ScrollView {
                                versionGroupedContent(allItems: items)
                            }
                            .frame(maxHeight: 320)
                        } else {
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
                                .padding()
                            }
                            .frame(maxHeight: 320)
                        }
                    }
                    .frame(width: 320)
                }
            }
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
    
    // 主内容+溢出处理
    private var contentWithOverflow: some View {
        let (visibleItems, _) = computeVisibleAndOverflowItems()
        return FlowLayout {
            ForEach(visibleItems) { item in
                FilterChip(
                    title: item.name,
                    isSelected: selectedItems.contains(item.id),
                    action: { toggleSelection(for: item.id) }
                )
            }
        }
        .frame(maxHeight: CategorySectionConstants.maxHeight)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, CategorySectionConstants.verticalPadding)
    }
    
    // 计算可见和溢出项
    private func computeVisibleAndOverflowItems() -> ([FilterItem], [FilterItem]) {
        // 先用FlowLayout测量每行，最多5行
        // 简化：假设每行最多6-8个，直接取前N个
        let maxRows = 5
        var rows: [[FilterItem]] = []
        var currentRow: [FilterItem] = []
        var currentRowWidth: CGFloat = 0
        let maxWidth: CGFloat = 320 // 估算宽度
        let chipPadding: CGFloat = 16 // 估算chip宽度padding
        for item in items {
            let estWidth = CGFloat(item.name.count) * 10 + chipPadding
            if currentRowWidth + estWidth > maxWidth, !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [item]
                currentRowWidth = estWidth
            } else {
                currentRow.append(item)
                currentRowWidth += estWidth
            }
        }
        if !currentRow.isEmpty { rows.append(currentRow) }
        let visibleRows = rows.prefix(maxRows)
        let visibleItems = visibleRows.flatMap { $0 }
        let overflowItems = Array(items.dropFirst(visibleItems.count))
        return (visibleItems, overflowItems)
    }
    
    // 版本分组内容
    @ViewBuilder
    private func versionGroupedContent(allItems: [FilterItem]) -> some View {
        // 按大版本分组，如1.20, 1.19, ...
        let groups = Dictionary(grouping: allItems) { (item: FilterItem) -> String in
            let comps = item.name.split(separator: ".")
            if comps.count >= 2 {
                return comps[0] + "." + comps[1]
            } else {
                return item.name
            }
        }
        let sortedKeys = groups.keys.sorted {
            let lhs = $0.split(separator: ".").compactMap { Int($0) }
            let rhs = $1.split(separator: ".").compactMap { Int($0) }
            return lhs.lexicographicallyPrecedes(rhs)
        }.reversed()
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(sortedKeys, id: \.self) { key in
                    Text(key)
                        .font(.headline.bold())
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                    FlowLayout {
                        ForEach(groups[key] ?? []) { item in
                            FilterChip(
                                title: item.name,
                                isSelected: selectedItems.contains(item.id),
                                action: { toggleSelection(for: item.id) }
                            )
                        }
                    }
                }
            }
            .padding()
        }
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
