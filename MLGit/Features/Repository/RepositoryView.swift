import Foundation
import SwiftUI

struct RepositoryView: View {
    let repositoryPath: String
    @State private var selectedTab = 0
    @StateObject private var viewModel: RepositoryViewModel
    @StateObject private var starredViewModel = StarredViewModel()
    
    enum Tab: Int, CaseIterable {
        case summary = 0
        case about = 1
        case code = 2
        case commits = 3
        case branches = 4
        
        var title: String {
            switch self {
            case .summary: return "Summary"
            case .about: return "About"
            case .code: return "Code"
            case .commits: return "Commits"
            case .branches: return "Branches"
            }
        }
        
        var icon: String {
            switch self {
            case .summary: return "info.circle"
            case .about: return "doc.text"
            case .code: return "doc.text.below.ecg"
            case .commits: return "clock"
            case .branches: return "arrow.triangle.branch"
            }
        }
    }
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self._viewModel = StateObject(wrappedValue: RepositoryViewModel(repositoryPath: repositoryPath))
        print("RepositoryView: Initialized with path: \(repositoryPath)")
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.repository == nil {
                ProgressView("Loading repository...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        print("RepositoryView: Showing loading state")
                    }
            } else if let repository = viewModel.repository {
                    let _ = print("RepositoryView: Showing repository content for: \(repository.name)")
                    VStack(spacing: 0) {
                    // Custom tab bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(Tab.allCases, id: \.rawValue) { tab in
                                TabButton(
                                    title: tab.title,
                                    icon: tab.icon,
                                    isSelected: selectedTab == tab.rawValue,
                                    action: { 
                                        selectedTab = tab.rawValue
                                        HapticManager.shared.selectionChanged()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground))
                    
                    Divider()
                    
                    // Tab content with lazy loading - only render current tab
                    Group {
                        switch Tab(rawValue: selectedTab) {
                        case .summary:
                            SummaryView(repositoryPath: repositoryPath)
                        case .about:
                            AboutView(repositoryPath: repositoryPath)
                        case .code:
                            EnhancedDirectoryView(repositoryPath: repositoryPath)
                        case .commits:
                            CommitsView(repositoryPath: repositoryPath)
                        case .branches:
                            RefsView(repositoryPath: repositoryPath)
                        case .none:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle(repository.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: toggleStar) {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .foregroundColor(isStarred ? .yellow : .primary)
                        }
                    }
                }
            } else {
                // No loading and no repository
                let _ = print("RepositoryView: No loading and no repository - blank state")
                Text("No repository data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.loadRepository()
        }
        // Removed aggressive request cancellation that was causing issues
        // Views should manage their own request lifecycle
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    private var isStarred: Bool {
        guard let repository = viewModel.repository else { return false }
        let project = Project(
            id: repository.id,
            name: repository.name,
            path: repository.path,
            description: repository.description,
            lastActivity: repository.lastUpdate,
            category: nil
        )
        return starredViewModel.isStarred(project)
    }
    
    private func toggleStar() {
        guard let repository = viewModel.repository else { return }
        let project = Project(
            id: repository.id,
            name: repository.name,
            path: repository.path,
            description: repository.description,
            lastActivity: repository.lastUpdate,
            category: nil
        )
        
        // Add haptic feedback
        if starredViewModel.isStarred(project) {
            HapticManager.shared.lightImpact()
        } else {
            HapticManager.shared.notificationSuccess()
        }
        
        starredViewModel.toggleStarred(project)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RepositoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RepositoryView(repositoryPath: "tosa/reference_model.git")
        }
    }
}
