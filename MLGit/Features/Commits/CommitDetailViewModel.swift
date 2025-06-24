import Foundation
import Combine

@MainActor
class CommitDetailViewModel: ObservableObject {
    @Published var commitDetail: CommitDetail?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let commitSHA: String
    private let gitService = GitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(repositoryPath: String, commitSHA: String) {
        self.repositoryPath = repositoryPath
        self.commitSHA = commitSHA
        
        gitService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    func loadCommit() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            commitDetail = try await gitService.fetchCommitDetail(
                repositoryPath: repositoryPath,
                sha: commitSHA
            )
        } catch {
            self.error = error
        }
    }
}