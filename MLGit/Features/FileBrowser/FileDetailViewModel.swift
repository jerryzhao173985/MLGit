import Foundation
import Combine

@MainActor
class FileDetailViewModel: ObservableObject {
    @Published var fileContent: FileContent? = nil
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    
    private let repositoryPath: String
    private let filePath: String
    private let gitService = GitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(repositoryPath: String, filePath: String) {
        self.repositoryPath = repositoryPath
        self.filePath = filePath
        print("FileDetailViewModel: init with path: \(filePath)")
    }
    
    func loadFile() async {
        print("FileDetailViewModel: loadFile() called for: \(filePath)")
        
        // Ensure we're on MainActor for all state updates
        isLoading = true
        error = nil
        fileContent = nil
        
        do {
            print("FileDetailViewModel: Fetching content...")
            let content = try await gitService.fetchFileContent(
                repositoryPath: repositoryPath,
                path: filePath,
                sha: nil
            )
            
            print("FileDetailViewModel: Content fetched - size: \(content.size), contentLength: \(content.content.count)")
            
            // Log specific file types
            if filePath.hasSuffix(".py") || filePath.hasSuffix(".gitignore") || filePath.hasSuffix(".sh") || filePath.hasSuffix(".bash") {
                print("FileDetailViewModel: Special file type detected: \(filePath)")
                print("FileDetailViewModel: Content preview (first 200 chars): \(String(content.content.prefix(200)))")
                print("FileDetailViewModel: Is binary: \(content.isBinary)")
                print("FileDetailViewModel: Encoding: \(content.encoding)")
            }
            
            // Update state - we're already on MainActor
            self.fileContent = content
            self.isLoading = false
            self.error = nil
            
            print("FileDetailViewModel: State updated - isLoading=\(isLoading), hasContent=\(fileContent != nil)")
            
        } catch {
            print("FileDetailViewModel: Error occurred: \(error)")
            self.error = error
            self.isLoading = false
            self.fileContent = nil
        }
    }
}