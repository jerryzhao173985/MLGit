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
    
    public override init() {
        super.init()
    }
    
    public func parse(html: String) throws -> RepositorySummary {
        print("SummaryParser: Starting to parse HTML (length: \(html.count))")
        let doc = try parseDocument(html)
        
        // Extract repository name from title or header
        let name = try extractRepositoryName(doc: doc)
        print("SummaryParser: Extracted repository name: \(name)")
        
        // Extract description from td.sub
        let description = try? doc.select("td.sub").first()?.text()
            .replacingOccurrences(of: "[no description]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let finalDescription = description?.isEmpty == false ? description : nil
        print("SummaryParser: Extracted description: \(finalDescription ?? "nil")")
        
        // Extract clone URLs
        let cloneURLs = try extractCloneURLs(doc: doc)
        print("SummaryParser: Found \(cloneURLs.count) clone URLs")
        
        // Extract last commit info from the Age/Commit message table
        let lastCommit = try extractLastCommit(doc: doc)
        print("SummaryParser: Extracted last commit: \(lastCommit?.sha.prefix(7) ?? "nil")")
        
        // Extract stats (branches, tags)
        let (branches, tags) = try extractBranchAndTagCounts(doc: doc)
        print("SummaryParser: Found \(branches) branches and \(tags) tags")
        
        return RepositorySummary(
            name: name,
            description: finalDescription,
            lastCommit: lastCommit,
            cloneURLs: cloneURLs,
            branches: branches,
            tags: tags,
            contributors: 0 // cgit doesn't show contributors on summary page
        )
    }
    
    private func extractRepositoryName(doc: Document) throws -> String {
        // Try to get from page title first
        if let title = try? doc.select("title").first()?.text() {
            // Title format: "repository.git - [no description]"
            if let dashIndex = title.firstIndex(of: "-") {
                let name = String(title[..<dashIndex]).trimmingCharacters(in: .whitespaces)
                return name.replacingOccurrences(of: ".git", with: "")
            }
        }
        
        // Try from breadcrumb
        if let lastLink = try? doc.select("td.main a").array().last {
            let text = try lastLink.text()
            return text.replacingOccurrences(of: ".git", with: "")
        }
        
        return "Unknown Repository"
    }
    
    private func extractCloneURLs(doc: Document) throws -> [RepositorySummary.CloneURL] {
        var urls: [RepositorySummary.CloneURL] = []
        
        // Look for the Clone section in the table
        let tables = try doc.select("table.list").array()
        
        for table in tables {
            let rows = try table.select("tr").array()
            
            for (index, row) in rows.enumerated() {
                // Look for Clone header
                if let th = try? row.select("th").first(),
                   try th.text().lowercased() == "clone",
                   index + 1 < rows.count {
                    
                    // Next row should contain the clone URL
                    let urlRow = rows[index + 1]
                    if let urlCell = try? urlRow.select("td").first(),
                       let link = try? urlCell.select("a").first() {
                        
                        let url = try link.text()
                        
                        if url.hasPrefix("https://") {
                            urls.append(RepositorySummary.CloneURL(type: .https, url: url))
                        } else if url.hasPrefix("git://") {
                            urls.append(RepositorySummary.CloneURL(type: .git, url: url))
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
        // Look for the Age/Commit message table
        let tables = try doc.select("table.list").array()
        
        for table in tables {
            let rows = try table.select("tr").array()
            
            // Find the table with Age/Commit message headers
            if let headerRow = rows.first,
               let headers = try? headerRow.select("th").array(),
               headers.count >= 3,
               try headers[0].text().lowercased().contains("age"),
               try headers[1].text().lowercased().contains("commit") {
                
                // Get the first data row
                if rows.count > 1 {
                    let dataRow = rows[1]
                    let cells = try dataRow.select("td").array()
                    
                    if cells.count >= 3 {
                        // Age cell (contains date)
                        let ageCell = cells[0]
                        let date = try extractDateFromAgeCell(ageCell)
                        
                        // Commit message cell
                        let messageCell = cells[1]
                        let messageLink = try messageCell.select("a").first()
                        let message = try messageLink?.text() ?? ""
                        
                        // Extract SHA from commit link href
                        let href = try messageLink?.attr("href") ?? ""
                        let sha = extractShaFromHref(href)
                        
                        // Author cell
                        let authorCell = cells[2]
                        let author = try authorCell.text()
                        
                        if !sha.isEmpty && !message.isEmpty {
                            return CommitSummaryInfo(
                                sha: sha,
                                message: message,
                                author: author,
                                date: date ?? Date()
                            )
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractBranchAndTagCounts(doc: Document) throws -> (branches: Int, tags: Int) {
        var branchCount = 0
        var tagCount = 0
        
        let tables = try doc.select("table.list").array()
        
        for table in tables {
            let rows = try table.select("tr").array()
            
            // Look for Branch table
            if let headerRow = rows.first,
               let th = try? headerRow.select("th").first(),
               try th.text().lowercased() == "branch" {
                // Count non-header rows
                branchCount = rows.count - 1
            }
            
            // Look for Tag table
            if let headerRow = rows.first,
               let th = try? headerRow.select("th").first(),
               try th.text().lowercased() == "tag" {
                // Count non-header rows, excluding the "[...]" row if present
                tagCount = rows.count - 1
                
                // Check if last row is "[...]"
                if let lastRow = rows.last,
                   let lastCell = try? lastRow.select("td").first(),
                   try lastCell.text().contains("[...]") {
                    tagCount -= 1
                }
            }
        }
        
        return (branchCount, tagCount)
    }
    
    private func extractDateFromAgeCell(_ cell: Element) throws -> Date? {
        // Look for span with title attribute containing the actual date
        if let span = try? cell.select("span").first(),
           let dateStr = try? span.attr("title") {
            // Date format: "2025-06-23 10:46:03 +0000"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: dateStr)
        }
        return nil
    }
    
    private func extractShaFromHref(_ href: String) -> String {
        // href format: "/tosa/reference_model.git/commit/?id=cd167baf693b155805622e340008388cc89f61b2"
        if let idRange = href.range(of: "id=") {
            let shaStart = href.index(idRange.upperBound, offsetBy: 0)
            var sha = String(href[shaStart...])
            
            // Remove any trailing parameters
            if let ampIndex = sha.firstIndex(of: "&") {
                sha = String(sha[..<ampIndex])
            }
            
            return sha
        }
        return ""
    }
    
    private func extractRepositoryPath(doc: Document) throws -> String {
        // Try to extract from breadcrumb
        if let breadcrumb = try? doc.select("td.main a").array() {
            for link in breadcrumb {
                let href = try link.attr("href")
                let text = try link.text()
                
                // Look for the repository link (ends with .git)
                if text.hasSuffix(".git") {
                    // Extract path from href
                    let path = href.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    return path
                }
            }
        }
        
        // Default fallback
        return "unknown/repository.git"
    }
}