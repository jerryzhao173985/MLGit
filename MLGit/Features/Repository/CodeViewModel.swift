import Foundation
import Combine

@MainActor
class CodeViewModel: ObservableObject {
    @Published var files: [FileNode] = []
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
    
    func loadFiles(path: String? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            files = try await gitService.fetchTree(
                repositoryPath: repositoryPath,
                path: path,
                sha: nil
            )
            
            files.sort { file1, file2 in
                if file1.isDirectory != file2.isDirectory {
                    return file1.isDirectory
                }
                return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
            }
        } catch {
            self.error = error
        }
    }
}