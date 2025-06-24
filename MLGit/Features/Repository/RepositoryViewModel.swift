import Foundation
import Combine

@MainActor
class RepositoryViewModel: ObservableObject {
    @Published var repository: Repository?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let gitService = GitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        
        gitService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    func loadRepository() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            repository = try await gitService.fetchRepository(path: repositoryPath)
        } catch {
            self.error = error
        }
    }
}