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
    
    private init(networkService: NetworkServiceProtocol? = nil) {
        self.networkService = networkService ?? NetworkService.shared
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
        
        // Check if file extension indicates binary
        let binaryExtensions = ["npy", "npz", "pkl", "pickle", "model", "h5", "hdf5", "mat", "bin", "dat", "db", "sqlite", "sqlite3", "tflite", "pb", "pth", "pt", "onnx", "caffemodel", "weights"]
        let fileExtension = (path as NSString).pathExtension.lowercased()
        let likelyBinaryByExtension = binaryExtensions.contains(fileExtension)
        
        do {
            // Try to get the plain content first
            let plainUrl = URLBuilder.plain(repositoryPath: repositoryPath, path: path, sha: sha)
            
            do {
                print("GitService: Fetching file content for: \(path)")
                print("GitService: Plain URL: \(plainUrl)")
                let data = try await requestManager.fetchData(from: plainUrl)
                print("GitService: Received data: \(data.count) bytes")
                
                // Check if the file is binary by examining the data or extension
                let isBinary = likelyBinaryByExtension || isLikelyBinary(data: data)
                
                var content = ""
                var encoding = "UTF-8"
                
                if !isBinary {
                    // Try multiple encodings for text files
                    let encodings: [(String.Encoding, String)] = [
                        (.utf8, "UTF-8"),
                        (.utf16, "UTF-16"),
                        (.utf16BigEndian, "UTF-16BE"),
                        (.utf16LittleEndian, "UTF-16LE"),
                        (.utf32, "UTF-32"),
                        (.isoLatin1, "ISO-8859-1"),
                        (.windowsCP1252, "Windows-1252"),
                        (.macOSRoman, "Mac OS Roman"),
                        (.ascii, "ASCII")
                    ]
                    
                    for (enc, name) in encodings {
                        if let decodedContent = String(data: data, encoding: enc) {
                            content = decodedContent
                            encoding = name
                            print("GitService: Successfully decoded with \(name) encoding: \(content.count) characters")
                            break
                        }
                    }
                    
                    // If all encodings fail, try ASCII with lossy conversion
                    if content.isEmpty && data.count > 0 {
                        print("GitService: All standard encodings failed, trying lossy ASCII conversion")
                        content = String(data: data, encoding: .ascii) ?? 
                                String(data.map { Character(UnicodeScalar($0)) })
                        encoding = "ASCII (lossy)"
                        print("GitService: Lossy conversion resulted in \(content.count) characters")
                    }
                } else {
                    print("GitService: Detected binary file based on content analysis")
                }
                
                // For binary files, encode the data as base64 for transport
                let finalContent = isBinary ? data.base64EncodedString() : content
                
                return FileContent(
                    path: path,
                    content: finalContent,
                    size: Int64(data.count),
                    encoding: isBinary ? "base64" : encoding,
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
    
    // Helper function to detect if data is likely binary
    private func isLikelyBinary(data: Data) -> Bool {
        // Empty files are not binary
        if data.isEmpty {
            return false
        }
        
        // Check first 8192 bytes (or entire file if smaller)
        let sampleSize = min(data.count, 8192)
        let sample = data.prefix(sampleSize)
        
        // Count null bytes and control characters
        var nullBytes = 0
        var controlChars = 0
        
        for byte in sample {
            if byte == 0 {
                nullBytes += 1
            } else if byte < 32 && byte != 9 && byte != 10 && byte != 13 {
                // Control chars except tab, newline, carriage return
                controlChars += 1
            }
        }
        
        // Check for common binary file signatures first
        if data.count >= 8 {
            let header = data.prefix(8)
            
            // PNG signature
            if header.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
                print("GitService: Detected PNG file signature")
                return true
            }
            
            // JPEG signatures
            if header.starts(with: [0xFF, 0xD8, 0xFF]) {
                print("GitService: Detected JPEG file signature")
                return true
            }
            
            // GIF signatures
            if header.starts(with: "GIF87a".data(using: .ascii)!) || 
               header.starts(with: "GIF89a".data(using: .ascii)!) {
                print("GitService: Detected GIF file signature")
                return true
            }
            
            // PDF signature
            if header.starts(with: "%PDF".data(using: .ascii)!) {
                print("GitService: Detected PDF file signature")
                return true
            }
            
            // NumPy .npy file signature
            if header.starts(with: [0x93, 0x4E, 0x55, 0x4D, 0x50, 0x59]) {
                print("GitService: Detected NumPy .npy file signature")
                return true
            }
        }
        
        // If more than 30% null bytes or control characters, likely binary
        let threshold = Double(sampleSize) * 0.3
        let isBinary = Double(nullBytes) > threshold || Double(controlChars) > threshold
        
        if isBinary {
            print("GitService: Binary detection - nullBytes: \(nullBytes), controlChars: \(controlChars), threshold: \(threshold)")
        }
        
        return isBinary
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