import Foundation
import SwiftSoup

public struct CommitInfo {
    public let sha: String
    public let shortSHA: String
    public let message: String
    public let shortMessage: String
    public let authorName: String
    public let authorEmail: String?
    public let date: Date
    public let decorations: [String] // Branch/tag decorations
    
    public init(sha: String, message: String, authorName: String, authorEmail: String?, date: Date, decorations: [String] = []) {
        self.sha = sha
        self.shortSHA = String(sha.prefix(7))
        self.message = message
        self.shortMessage = message.components(separatedBy: "\n").first ?? message
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.date = date
        self.decorations = decorations
    }
}

public struct CommitListResult {
    public let commits: [CommitInfo]
    public let hasMore: Bool
    public let nextOffset: Int?
    
    public init(commits: [CommitInfo], hasMore: Bool, nextOffset: Int?) {
        self.commits = commits
        self.hasMore = hasMore
        self.nextOffset = nextOffset
    }
}

public class CommitListParser: BaseParser, HTMLParserProtocol {
    public typealias Output = CommitListResult
    
    public override init() {
        super.init()
    }
    
    public func parse(html: String) throws -> CommitListResult {
        let doc = try parseDocument(html)
        
        // Look for table with class 'list nowrap'
        let tables = try doc.select("table.list.nowrap").array()
        guard let table = tables.first else {
            throw ParserError.missingElement(selector: "table.list.nowrap")
        }
        
        let rows = try table.select("tr").array()
        var commits: [CommitInfo] = []
        
        for row in rows {
            // Skip header row
            if try row.hasClass("nohover") && row.select("th").count > 0 {
                continue
            }
            
            let cells = try row.select("td").array()
            
            // Expected structure: Age | Commit message | Author
            guard cells.count >= 3 else { continue }
            
            let ageCell = cells[0]
            let messageCell = cells[1]
            let authorCell = cells[2]
            
            // Extract date from age cell
            let date = try extractDateFromAgeCell(ageCell) ?? Date()
            
            // Extract commit message and SHA
            guard let messageLink = try messageCell.select("a").first() else { continue }
            let message = try messageLink.text()
            let href = try messageLink.attr("href")
            let sha = extractSHA(from: href)
            
            // Extract decorations (branches/tags)
            let decorations = try extractDecorations(from: messageCell)
            
            // Extract author
            let authorName = try authorCell.text()
            
            let commit = CommitInfo(
                sha: sha,
                message: message,
                authorName: authorName,
                authorEmail: nil, // cgit log doesn't show email
                date: date,
                decorations: decorations
            )
            
            commits.append(commit)
        }
        
        // Check for pagination
        let (hasMore, nextOffset) = try extractPagination(doc: doc)
        
        return CommitListResult(
            commits: commits,
            hasMore: hasMore,
            nextOffset: nextOffset
        )
    }
    
    private func extractDateFromAgeCell(_ cell: Element) throws -> Date? {
        // Check for span with age class and title attribute
        if let span = try? cell.select("span[class^=age]").first(),
           let dateStr = try? span.attr("title") {
            // Date format: "2025-06-23 10:46:03 +0000"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: dateStr)
        }
        
        // Fallback: try to parse the text directly if it's a date
        let text = try cell.text()
        if text.contains("-") {
            // Try parsing as date string
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter.date(from: text)
        }
        
        return nil
    }
    
    private func extractSHA(from href: String) -> String {
        // href format: "/tosa/reference_model.git/commit/?id=SHA"
        if let idRange = href.range(of: "id=") {
            let sha = String(href[href.index(idRange.upperBound, offsetBy: 0)...])
            if let ampIndex = sha.firstIndex(of: "&") {
                return String(sha[..<ampIndex])
            }
            return sha
        }
        return ""
    }
    
    private func extractDecorations(from cell: Element) throws -> [String] {
        var decorations: [String] = []
        
        // Look for decoration spans
        let decorationSpans = try cell.select("span.decoration").array()
        for span in decorationSpans {
            // Extract text from decoration links
            let decoLinks = try span.select("a").array()
            for link in decoLinks {
                let text = try link.text()
                if !text.isEmpty {
                    decorations.append(text)
                }
            }
        }
        
        return decorations
    }
    
    private func extractPagination(doc: Document) throws -> (hasMore: Bool, nextOffset: Int?) {
        // Look for "[...]" link or pagination links
        let links = try doc.select("a").array()
        
        for link in links {
            let text = try link.text()
            let href = try link.attr("href")
            
            // Check for "next" or "[...]" links
            if text.contains("[...]") || text.lowercased().contains("next") {
                // Extract offset from href
                if let ofsRange = href.range(of: "ofs=") {
                    let offsetStr = String(href[href.index(ofsRange.upperBound, offsetBy: 0)...])
                    let numberPart = offsetStr.prefix(while: { $0.isNumber })
                    if let offset = Int(numberPart) {
                        return (true, offset)
                    }
                }
                return (true, nil)
            }
        }
        
        return (false, nil)
    }
}