import Foundation
import Combine
import GitHTMLParser

@MainActor
class CommitsViewModel: ObservableObject {
    @Published var commits: [CommitSummary] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let gitService = GitService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentOffset = 0
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        
        gitService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    func loadCommits() async {
        isLoading = true
        defer { isLoading = false }
        
        currentOffset = 0
        commits = []
        
        do {
            let result = try await gitService.fetchCommits(
                repositoryPath: repositoryPath,
                offset: currentOffset
            )
            
            commits = result.commits.map { info in
                CommitSummary(
                    id: info.sha,
                    sha: info.sha,
                    message: info.message,
                    authorName: info.authorName,
                    authorEmail: info.authorEmail,
                    date: info.date,
                    shortMessage: info.shortMessage
                )
            }
            
            hasMore = result.hasMore
            currentOffset = result.nextOffset ?? 0
        } catch {
            self.error = error
        }
    }
    
    func loadMoreCommits() async {
        guard !isLoadingMore && hasMore else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let result = try await gitService.fetchCommits(
                repositoryPath: repositoryPath,
                offset: currentOffset
            )
            
            let newCommits = result.commits.map { info in
                CommitSummary(
                    id: info.sha,
                    sha: info.sha,
                    message: info.message,
                    authorName: info.authorName,
                    authorEmail: info.authorEmail,
                    date: info.date,
                    shortMessage: info.shortMessage
                )
            }
            
            commits.append(contentsOf: newCommits)
            hasMore = result.hasMore
            currentOffset = result.nextOffset ?? currentOffset
        } catch {
            self.error = error
        }
    }
}