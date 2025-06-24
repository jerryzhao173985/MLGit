import Foundation
import SwiftSoup

public struct RepositorySummary {
    public let name: String
    public let description: String?
    public let lastCommit: CommitSummaryInfo?
    public let cloneURLs: [CloneURL]
    public let branches: Int
    public let tags: Int
    public let contributors: Int
    
    public struct CloneURL {
        public let type: URLType
        public let url: String
        
        public enum URLType: String {
            case https = "HTTPS"
            case ssh = "SSH"
            case git = "Git"
        }
        
        public init(type: URLType, url: String) {
            self.type = type
            self.url = url
        }
    }
    
    public init(name: String, description: String?, lastCommit: CommitSummaryInfo?, 
                cloneURLs: [CloneURL], branches: Int, tags: Int, contributors: Int) {
        self.name = name
        self.description = description
        self.lastCommit = lastCommit
        self.cloneURLs = cloneURLs
        self.branches = branches
        self.tags = tags
        self.contributors = contributors
    }
}

public struct CommitSummaryInfo {
    public let sha: String
    public let message: String
    public let author: String
    public let date: Date
    
    public init(sha: String, message: String, author: String, date: Date) {
        self.sha = sha
        self.message = message
        self.author = author
        self.date = date
    }
}

public class SummaryParser: BaseParser, HTMLParserProtocol {
    public typealias Output = RepositorySummary
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    public override init() {
        super.init()
    }
    
    public func parse(html: String) throws -> RepositorySummary {
        let doc = try parseDocument(html)
        
        // Extract repository name from title or header
        let name = try extractRepositoryName(doc: doc)
        
        // Extract description if available
        let description = try? doc.select("div.desc").first()?.text()
        
        // Extract clone URLs
        let cloneURLs = try extractCloneURLs(doc: doc)
        
        // Extract last commit info
        let lastCommit = try extractLastCommit(doc: doc)
        
        // Extract stats (branches, tags, contributors)
        let (branches, tags, contributors) = try extractStats(doc: doc)
        
        return RepositorySummary(
            name: name,
            description: description,
            lastCommit: lastCommit,
            cloneURLs: cloneURLs,
            branches: branches,
            tags: tags,
            contributors: contributors
        )
    }
    
    private func extractRepositoryName(doc: Document) throws -> String {
        // Try to get from page title first
        if let title = try? doc.select("title").first()?.text() {
            // Remove suffix like " - summary"
            if let dashIndex = title.firstIndex(of: "-") {
                return String(title[..<dashIndex]).trimmingCharacters(in: .whitespaces)
            }
            return title
        }
        
        // Try from header
        if let header = try? doc.select("td.main a").array().last?.text() {
            return header.replacingOccurrences(of: ".git", with: "")
        }
        
        return "Unknown Repository"
    }
    
    private func extractCloneURLs(doc: Document) throws -> [RepositorySummary.CloneURL] {
        var urls: [RepositorySummary.CloneURL] = []
        
        // Look for clone URL section
        let tables = try doc.select("table").array()
        for table in tables {
            let rows = try table.select("tr").array()
            for row in rows {
                let cells = try row.select("td").array()
                if cells.count >= 2 {
                    let label = try cells[0].text().lowercased()
                    let value = try cells[1].text()
                    
                    if label.contains("clone") || label.contains("url") {
                        if value.hasPrefix("https://") {
                            urls.append(RepositorySummary.CloneURL(type: .https, url: value))
                        } else if value.hasPrefix("git://") {
                            urls.append(RepositorySummary.CloneURL(type: .git, url: value))
                        } else if value.contains("@") && value.contains(":") {
                            urls.append(RepositorySummary.CloneURL(type: .ssh, url: value))
                        }
                    }
                }
            }
        }
        
        // If no clone URLs found, construct default HTTPS URL
        if urls.isEmpty {
            let repoPath = try extractRepositoryPath(doc: doc)
            let httpsURL = "https://git.mlplatform.org/\(repoPath)"
            urls.append(RepositorySummary.CloneURL(type: .https, url: httpsURL))
        }
        
        return urls
    }
    
    private func extractLastCommit(doc: Document) throws -> CommitSummaryInfo? {
        // Look for commit info in summary view
        let tables = try doc.select("table.list").array()
        
        for table in tables {
            // Check if this is the commit table
            let rows = try table.select("tr").array()
            if rows.count > 1 {
                let firstDataRow = rows[1]
                let cells = try firstDataRow.select("td").array()
                
                if cells.count >= 3 {
                    // Try to extract commit info
                    var sha = ""
                    var message = ""
                    var author = ""
                    var date = Date()
                    
                    // Look for commit SHA link
                    if let shaLink = try cells[0].select("a").first() {
                        sha = try shaLink.text()
                    }
                    
                    // Look for commit message
                    if cells.count > 1, let msgLink = try cells[1].select("a").first() {
                        message = try msgLink.text()
                    }
                    
                    // Look for author
                    if cells.count > 2 {
                        author = try cells[2].text()
                    }
                    
                    // Look for date
                    if cells.count > 3 {
                        let dateText = try cells[3].text()
                        date = dateFormatter.date(from: dateText) ?? Date()
                    }
                    
                    if !sha.isEmpty && !message.isEmpty {
                        return CommitSummaryInfo(
                            sha: sha,
                            message: message,
                            author: author,
                            date: date
                        )
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractStats(doc: Document) throws -> (branches: Int, tags: Int, contributors: Int) {
        var branches = 0
        var tags = 0
        var contributors = 0
        
        // Look for stats in various places
        let allText = try doc.text()
        
        // Try to find branch count
        if let branchMatch = allText.range(of: #"(\d+)\s*branch"#, options: .regularExpression) {
            let numberText = String(allText[branchMatch]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            branches = Int(numberText) ?? 0
        }
        
        // Try to find tag count
        if let tagMatch = allText.range(of: #"(\d+)\s*tag"#, options: .regularExpression) {
            let numberText = String(allText[tagMatch]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            tags = Int(numberText) ?? 0
        }
        
        // Try to find contributor count
        if let contribMatch = allText.range(of: #"(\d+)\s*contributor"#, options: .regularExpression) {
            let numberText = String(allText[contribMatch]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            contributors = Int(numberText) ?? 0
        }
        
        return (branches, tags, contributors)
    }
    
    private func extractRepositoryPath(doc: Document) throws -> String {
        // Try to extract from breadcrumb or URL
        if let breadcrumb = try? doc.select("td.main a").array() {
            for link in breadcrumb {
                let href = try link.attr("href")
                if href.hasSuffix(".git/") || href.hasSuffix(".git") {
                    return href.replacingOccurrences(of: "/", with: "")
                        .replacingOccurrences(of: ".git", with: ".git")
                }
            }
        }
        
        // Default fallback
        return "unknown/repository.git"
    }
}