import Foundation
import Combine

@MainActor
class RepositoryViewModel: ObservableObject {
    @Published var repository: Repository?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let gitService = GitService.shared
    private let repositoryStorage = RepositoryStorage.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedOnce = false
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        
        gitService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
        
        // Pre-populate with cached project data if available
        if let project = repositoryStorage.repository(for: repositoryPath) {
            self.repository = Repository(
                id: project.id,
                name: project.name,
                path: project.path,
                description: project.description,
                readme: nil,
                defaultBranch: "main",
                lastUpdate: project.lastActivity ?? Date()
            )
        }
    }
    
    func loadRepository() async {
        // Skip if already loading or loaded
        guard !isLoading && !hasLoadedOnce else { return }
        
        hasLoadedOnce = true
        isLoading = true
        defer { isLoading = false }
        
        do {
            repository = try await gitService.fetchRepository(path: repositoryPath)
        } catch {
            self.error = error
            // Keep cached repository data if available
        }
    }
}