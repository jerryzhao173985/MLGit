import Foundation
import Combine
import GitHTMLParser

@MainActor
class DiffViewModel: ObservableObject {
    @Published var diffFiles: [LegacyDiffFile]?
    @Published var rawPatch: String?
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
    
    func loadDiff() async {
        isLoading = true
        defer { isLoading = false }
        
        print("DiffViewModel: Loading diff for commit: \(commitSHA)")
        
        do {
            // First try to get structured diff data
            let gitDiffFiles = try await gitService.fetchDiff(
                repositoryPath: repositoryPath,
                sha: commitSHA
            )
            
            print("DiffViewModel: Loaded \(gitDiffFiles.count) diff files")
            
            if !gitDiffFiles.isEmpty {
                // Convert GitHTMLParser models to our view models
                diffFiles = gitDiffFiles.map { gitFile in
                    LegacyDiffFile(
                        path: gitFile.newPath,
                        oldPath: gitFile.oldPath,
                        changeType: mapChangeType(gitFile.changeType),
                        additions: calculateAdditions(from: gitFile.hunks),
                        deletions: calculateDeletions(from: gitFile.hunks),
                        hunks: gitFile.hunks.map { gitHunk in
                            LegacyDiffHunk(
                                header: gitHunk.header,
                                oldStart: gitHunk.oldStart,
                                oldCount: gitHunk.oldCount,
                                newStart: gitHunk.newStart,
                                newCount: gitHunk.newCount,
                                lines: gitHunk.lines.map { gitLine in
                                    LegacyDiffLine(
                                        type: mapLineType(gitLine.type),
                                        content: gitLine.content,
                                        oldLineNumber: gitLine.oldLineNumber,
                                        newLineNumber: gitLine.newLineNumber
                                    )
                                }
                            )
                        }
                    )
                }
            }
            
            // Also get raw patch as fallback
            rawPatch = try await gitService.fetchPatch(
                repositoryPath: repositoryPath,
                sha: commitSHA
            )
            
            if let patch = rawPatch {
                print("DiffViewModel: Loaded raw patch - length: \(patch.count)")
            }
            
        } catch {
            print("DiffViewModel: Error loading diff - \(error)")
            self.error = error
            
            // Try to at least get the raw patch
            do {
                rawPatch = try await gitService.fetchPatch(
                    repositoryPath: repositoryPath,
                    sha: commitSHA
                )
            } catch {
                print("DiffViewModel: Error loading patch fallback - \(error)")
            }
        }
    }
    
    private func mapChangeType(_ type: GitHTMLParser.DiffFile.ChangeType) -> LegacyDiffFile.ChangeType {
        switch type {
        case .added:
            return .added
        case .modified:
            return .modified
        case .deleted:
            return .deleted
        case .renamed:
            return .renamed
        case .copied:
            return .copied
        }
    }
    
    private func mapLineType(_ type: GitHTMLParser.DiffLine.LineType) -> LegacyDiffLine.LineType {
        switch type {
        case .addition:
            return .addition
        case .deletion:
            return .deletion
        case .context:
            return .context
        case .noNewline:
            return .context // Map noNewline to context as a fallback
        }
    }
    
    private func calculateAdditions(from hunks: [GitHTMLParser.DiffHunk]) -> Int {
        hunks.reduce(0) { total, hunk in
            total + hunk.lines.filter { $0.type == .addition }.count
        }
    }
    
    private func calculateDeletions(from hunks: [GitHTMLParser.DiffHunk]) -> Int {
        hunks.reduce(0) { total, hunk in
            total + hunk.lines.filter { $0.type == .deletion }.count
        }
    }
}