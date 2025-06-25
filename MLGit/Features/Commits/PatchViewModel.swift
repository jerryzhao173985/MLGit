import Foundation
import Combine

@MainActor
class PatchViewModel: ObservableObject {
    @Published var patch: String?
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
    
    func loadPatch() async {
        isLoading = true
        defer { isLoading = false }
        
        print("PatchViewModel: Loading patch for commit: \(commitSHA)")
        
        do {
            patch = try await gitService.fetchPatch(
                repositoryPath: repositoryPath,
                sha: commitSHA
            )
            
            if let patch = patch {
                print("PatchViewModel: Loaded patch - length: \(patch.count)")
                if patch.isEmpty {
                    print("PatchViewModel: WARNING - Patch is empty!")
                }
            } else {
                print("PatchViewModel: No patch returned")
            }
        } catch {
            print("PatchViewModel: Error loading patch - \(error)")
            self.error = error
        }
    }
}