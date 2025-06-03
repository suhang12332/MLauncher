import SwiftUI

// MARK: - Main View
struct ModrinthDetailView: View {
    // MARK: - Properties
    let query: String
    @Binding var currentPage: Int
    @Binding var totalItems: Int
    @Binding var sortIndex: String
    @Binding var selectedVersions: [String]
    @Binding var selectedCategories: [String]
    @Binding var selectedFeatures: [String]
    @Binding var selectedResolutions: [String]
    @Binding var selectedPerformanceImpact: [String]
    @Binding var selectedProjectId: String?
    
    @StateObject private var viewModel = ModrinthSearchViewModel()
    @State private var hasLoaded = false
    @State var searchText: String=""
    
    // Timer to implement debounce for search
    @State private var searchTimer: Timer? = nil
    
    // MARK: - Body
    var body: some View {
        VStack {
            if viewModel.isLoading {
                EmptyView()
            } else if let error = viewModel.error {
                ErrorView(error)
            } else if viewModel.results.isEmpty {
                EmptyResultView()
            } else {
                resultList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if !hasLoaded {
                hasLoaded = true
                await performSearch()
            }
        }
        .onChange(of: currentPage) { _, _ in
            Task { await performSearch() }
        }
        .onChange(of: query) { _, _ in
            currentPage = 1
            Task { await performSearch() }
        }
        .onChange(of: viewModel.totalHits) { _, newValue in
            totalItems = newValue
        }
        .onChange(of: sortIndex) { _, _ in
            Task { await performSearch() }
        }
        .onChange(of: selectedVersions) { _, _ in
            currentPage = 1
            Task { await performSearch() }
        }
        .onChange(of: selectedCategories) { _, _ in
            currentPage = 1
            Task { await performSearch() }
        }
        .onChange(of: selectedFeatures) { _, _ in
            currentPage = 1
            Task { await performSearch() }
        }
        .onChange(of: selectedResolutions) { _, _ in
            currentPage = 1
            Task { await performSearch() }
        }
        .onChange(of: selectedPerformanceImpact) { _, _ in
            currentPage = 1
            Task { await performSearch() }
        }
        
        .refreshable {
            await performSearch()
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { _, newValue in // Listen for changes in searchText
             // Invalidate previous timer if exists
             searchTimer?.invalidate()
             // Start a new timer
             searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                 // Perform search after a short delay (debounce)
                 Task { await performSearch() }
             }
         }
        
    }
    
    // MARK: - Private Methods
    private func performSearch() async {
        await viewModel.search(
            projectType: query,
            page: currentPage,
            query: searchText, // Use searchText for the search query
            sortIndex: sortIndex,
            versions: selectedVersions,
            categories: selectedCategories,
            features: selectedFeatures,
            resolutions: selectedResolutions,
            performanceImpact: selectedPerformanceImpact
        )
    }
    
    
    
    
   
    
    private var resultList: some View {
        ForEach(viewModel.results, id: \.projectId) { mod in
            ModrinthDetailCardView(mod: mod)
                .padding(.vertical, ModrinthConstants.UI.verticalPadding)
                .listRowInsets(
                    EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                )
                .onTapGesture {
                    selectedProjectId = mod.projectId
                }
        }
    }
}

