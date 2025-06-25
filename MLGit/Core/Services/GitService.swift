import Foundation
import Combine
import GitHTMLParser

@MainActor
class GitService: ObservableObject {
    private static let _shared = GitService()
    
    static var shared: GitService {
        return _shared
    }
    
    // Serial queue to prevent race conditions
    private let requestQueue = DispatchQueue(label: "com.mlgit.gitservice", attributes: .concurrent)
    
    private let networkService: NetworkServiceProtocol
    private let requestManager = RequestManager.shared
    private let catalogueParser = CatalogueParser()
    private let commitListParser = CommitListParser()
    private let treeParser = TreeParser()
    private let refsParser = RefsParser()
    private let commitDetailParser = CommitDetailParser()
    private let diffParser = DiffParser()
    private let summaryParser = SummaryParser()
    private let aboutParser = AboutParser()
    private let fileContentParser = FileContentParser()
    
    @Published var isLoading = false
    @Published var error: Error?
    
    private init(networkService: NetworkServiceProtocol = NetworkService.shared) {
        self.networkService = networkService
    }
    
    func fetchProjects() async throws -> [Project] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URLBuilder.catalogue()
            let html = try await requestManager.fetchHTML(from: url)
            
            do {
                let projectInfos = try catalogueParser.parse(html: html)
                
                return projectInfos.map { info in
                    Project(
                        id: info.path,
                        name: info.name,
                        path: info.path,
                        description: info.description,
                        lastActivity: info.lastActivity,
                        category: info.category
                    )
                }
            } catch let parseError {
                print("GitService: Parser error - \(parseError)")
                if let parserError = parseError as? ParserError {
                    throw parserError
                } else {
                    throw NetworkError.parsingError("Failed to parse repository list: \(parseError.localizedDescription)")
                }
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchRepository(path: String) async throws -> Repository {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let aboutURL = URLBuilder.about(repositoryPath: path)
            let aboutHTML = try await requestManager.fetchHTML(from: aboutURL)
            
            let repository = Repository(
                id: path,
                name: path.split(separator: "/").last.map(String.init) ?? path,
                path: path,
                description: nil,
                readme: extractReadme(from: aboutHTML),
                defaultBranch: "main",
                lastUpdate: Date()
            )
            
            return repository
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchCommits(repositoryPath: String, offset: Int = 0) async throws -> CommitListResult {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URLBuilder.log(repositoryPath: repositoryPath, offset: offset)
            let html = try await requestManager.fetchHTML(from: url)
            let result = try commitListParser.parse(html: html)
            
            return result
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchCommitDetail(repositoryPath: String, sha: String) async throws -> CommitDetail {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URLBuilder.commit(repositoryPath: repositoryPath, sha: sha)
            let html = try await requestManager.fetchHTML(from: url)
            
            return try parseCommitDetail(from: html, sha: sha)
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchPatch(repositoryPath: String, sha: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URLBuilder.patch(repositoryPath: repositoryPath, sha: sha)
            let patch = try await requestManager.fetchHTML(from: url)
            return patch
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchTree(repositoryPath: String, path: String? = nil, sha: String? = nil) async throws -> [FileNode] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URLBuilder.tree(repositoryPath: repositoryPath, path: path, sha: sha)
            print("GitService: Fetching tree for path: \(path ?? "root")")
            let html = try await requestManager.fetchHTML(from: url)
            let treeNodes = try treeParser.parse(html: html)
            
            return treeNodes.map { node in
                FileNode(
                    id: node.path,
                    name: node.name,
                    path: node.path,
                    type: mapNodeType(node.type),
                    mode: node.mode,
                    size: node.size,
                    lastCommit: nil
                )
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchRefs(repositoryPath: String) async throws -> RefsResult {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URLBuilder.refs(repositoryPath: repositoryPath)
            let html = try await requestManager.fetchHTML(from: url)
            return try refsParser.parse(html: html)
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchRepositorySummary(repositoryPath: String) async throws -> RepositorySummary {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Use the summary URL instead of repository URL
            let url = URLBuilder.summary(repositoryPath: repositoryPath)
            print("GitService: Fetching repository summary from: \(url)")
            let html = try await requestManager.fetchHTML(from: url)
            return try summaryParser.parse(html: html)
        } catch {
            print("GitService: Failed to fetch repository summary - \(error)")
            self.error = error
            throw error
        }
    }
    
    func fetchAboutContent(repositoryPath: String) async throws -> AboutContent {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URLBuilder.about(repositoryPath: repositoryPath)
            let html = try await requestManager.fetchHTML(from: url)
            return try aboutParser.parse(html: html)
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchDiff(repositoryPath: String, sha: String) async throws -> [GitHTMLParser.DiffFile] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let url = URLBuilder.diff(repositoryPath: repositoryPath, sha: sha)
            let html = try await requestManager.fetchHTML(from: url)
            return try diffParser.parse(html: html)
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchFileContent(repositoryPath: String, path: String, sha: String? = nil) async throws -> FileContent {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try to get the plain content first
            let plainUrl = URLBuilder.plain(repositoryPath: repositoryPath, path: path, sha: sha)
            
            do {
                print("GitService: Fetching file content for: \(path)")
                print("GitService: Plain URL: \(plainUrl)")
                let data = try await requestManager.fetchData(from: plainUrl)
                print("GitService: Received data: \(data.count) bytes")
                
                let content = String(data: data, encoding: .utf8) ?? ""
                let isBinary = content.isEmpty && data.count > 0
                
                if isBinary {
                    print("GitService: Detected binary file (no UTF-8 content but \(data.count) bytes)")
                } else {
                    print("GitService: Decoded text content: \(content.count) characters")
                }
                
                return FileContent(
                    path: path,
                    content: content,
                    size: Int64(data.count),
                    encoding: "UTF-8",
                    isBinary: isBinary
                )
            } catch {
                // If plain fails, try parsing the blob HTML page
                print("GitService: Plain fetch failed with error: \(error)")
                print("GitService: Trying blob HTML for: \(path)")
                
                let blobUrl = URLBuilder.blob(repositoryPath: repositoryPath, path: path, sha: sha)
                print("GitService: Blob URL: \(blobUrl)")
                
                let html = try await requestManager.fetchHTML(from: blobUrl)
                print("GitService: Received HTML: \(html.count) characters")
                
                let fileInfo = try fileContentParser.parse(html: html)
                print("GitService: Parsed file info - content: \(fileInfo.content.count) chars, binary: \(fileInfo.isBinary)")
                
                return FileContent(
                    path: fileInfo.path,
                    content: fileInfo.content,
                    size: fileInfo.size ?? Int64(fileInfo.content.utf8.count),
                    encoding: "UTF-8",
                    isBinary: fileInfo.isBinary
                )
            }
        } catch {
            self.error = error
            throw error
        }
    }
    
    private func extractReadme(from html: String) -> String? {
        guard let startRange = html.range(of: "<div class=\"readme\">"),
              let endRange = html.range(of: "</div>", range: startRange.upperBound..<html.endIndex) else {
            return nil
        }
        
        let readmeHTML = String(html[startRange.upperBound..<endRange.lowerBound])
        return readmeHTML.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseCommitDetail(from html: String, sha: String) throws -> CommitDetail {
        let commitDetailInfo = try commitDetailParser.parse(html: html)
        
        return CommitDetail(
            id: commitDetailInfo.sha,
            sha: commitDetailInfo.sha,
            message: commitDetailInfo.message,
            authorName: commitDetailInfo.authorName,
            authorEmail: commitDetailInfo.authorEmail,
            authorDate: commitDetailInfo.authorDate,
            committerName: commitDetailInfo.committerName,
            committerEmail: commitDetailInfo.committerEmail,
            committerDate: commitDetailInfo.committerDate,
            parents: commitDetailInfo.parents,
            tree: commitDetailInfo.tree,
            diffStats: commitDetailInfo.diffStats.map { stats in
                DiffStats(
                    filesChanged: stats.filesChanged,
                    insertions: stats.insertions,
                    deletions: stats.deletions
                )
            },
            changedFiles: commitDetailInfo.changedFiles.map { file in
                ChangedFile(
                    id: file.path,
                    path: file.path,
                    oldPath: nil,
                    changeType: mapChangeType(file.changeType),
                    additions: file.additions,
                    deletions: file.deletions
                )
            }
        )
    }
    
    private func mapNodeType(_ type: TreeNode.NodeType) -> FileNode.NodeType {
        switch type {
        case .file:
            return .file
        case .directory:
            return .directory
        case .symlink:
            return .symlink
        case .submodule:
            return .submodule
        }
    }
    
    private func mapChangeType(_ type: GitHTMLParser.GitChangedFile.ChangeType) -> ChangedFile.ChangeType {
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
}