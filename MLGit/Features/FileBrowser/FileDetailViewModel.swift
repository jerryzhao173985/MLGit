import Foundation
import Combine

@MainActor
class FileDetailViewModel: ObservableObject {
    @Published var fileContent: FileContent?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let filePath: String
    private let gitService = GitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(repositoryPath: String, filePath: String) {
        self.repositoryPath = repositoryPath
        self.filePath = filePath
        
        gitService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    func loadFile() async {
        isLoading = true
        defer { isLoading = false }
        
        print("FileDetailViewModel: Loading file - repository: \(repositoryPath), path: \(filePath)")
        
        do {
            fileContent = try await gitService.fetchFileContent(
                repositoryPath: repositoryPath,
                path: filePath,
                sha: nil
            )
            
            if let content = fileContent {
                print("FileDetailViewModel: Loaded file - size: \(content.size), isBinary: \(content.isBinary), contentLength: \(content.content.count)")
            } else {
                print("FileDetailViewModel: No content returned")
            }
        } catch {
            print("FileDetailViewModel: Error loading file - \(error)")
            self.error = error
        }
    }
}