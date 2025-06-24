import Foundation
import Combine
import GitHTMLParser

@MainActor
class RefsViewModel: ObservableObject {
    @Published var branches: [Ref] = []
    @Published var tags: [Ref] = []
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
    
    func loadRefs() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await gitService.fetchRefs(repositoryPath: repositoryPath)
            branches = result.branches.map { refInfo in
                Ref(
                    id: refInfo.name,
                    name: refInfo.name,
                    commitSHA: refInfo.commitSHA,
                    commitMessage: refInfo.commitMessage,
                    authorName: refInfo.authorName,
                    date: refInfo.date,
                    type: .branch
                )
            }
            tags = result.tags.map { refInfo in
                Ref(
                    id: refInfo.name,
                    name: refInfo.name,
                    commitSHA: refInfo.commitSHA,
                    commitMessage: refInfo.commitMessage,
                    authorName: refInfo.authorName,
                    date: refInfo.date,
                    type: .tag
                )
            }
        } catch {
            self.error = error
        }
    }
}