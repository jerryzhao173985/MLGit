import Foundation
import Combine

@MainActor
class ExploreViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?
    
    private let repositoryStorage = RepositoryStorage.shared
    private let gitService = GitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var categories: [String] {
        return repositoryStorage.categories
    }
    
    init() {
        // Subscribe to repository updates
        repositoryStorage.$repositories
            .sink { [weak self] repositories in
                self?.projects = repositories
            }
            .store(in: &cancellables)
        
        repositoryStorage.$lastUpdated
            .sink { [weak self] date in
                self?.lastUpdated = date
            }
            .store(in: &cancellables)
        
        gitService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
        
        // Load stored repositories immediately
        Task {
            await loadStoredProjects()
        }
    }
    
    func loadProjects() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // First, show cached data immediately
        projects = await repositoryStorage.getRepositories()
        
        // Then refresh if needed
        if repositoryStorage.needsUpdate {
            do {
                try await repositoryStorage.refreshRepositories()
                error = nil
            } catch {
                self.error = error
                // We still have cached data, so don't clear projects
            }
        }
    }
    
    private func loadStoredProjects() async {
        // Load from storage without network call
        projects = repositoryStorage.repositories
        
        // If no stored data, load from network
        if projects.isEmpty {
            await loadProjects()
        }
    }
}