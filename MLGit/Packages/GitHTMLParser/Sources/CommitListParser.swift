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
    
    public init(sha: String, message: String, authorName: String, authorEmail: String?, date: Date) {
        self.sha = sha
        self.shortSHA = String(sha.prefix(7))
        self.message = message
        self.shortMessage = message.components(separatedBy: "\n").first ?? message
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.date = date
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
        
        // Look for table with class containing 'list'
        let tables = try doc.select("table").array()
        guard let table = tables.first(where: { element in
            (try? element.className().contains("list")) ?? false
        }) else {
            throw ParserError.missingElement(selector: "table with class 'list'")
        }
        
        let rows = try table.select("tr").array()
        var commits: [CommitInfo] = []
        
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            let cells = try row.select("td").array()
            guard cells.count >= 3 else { continue }
            
            let ageCell = cells[0]
            let commitCell = cells[1]
            let authorCell = cells[2]
            
            guard let commitLink = try commitCell.select("a").first() else {
                continue
            }
            let href = try commitLink.attr("href")
            guard let sha = extractSHA(from: href) else {
                continue
            }
            
            let message = try commitLink.text()
            
            let authorText = try authorCell.text()
            let (authorName, authorEmail) = parseAuthor(from: authorText)
            
            let ageText = try ageCell.text()
            guard let date = parseDate(from: ageText) else {
                continue
            }
            
            let commit = CommitInfo(
                sha: sha,
                message: message,
                authorName: authorName,
                authorEmail: authorEmail,
                date: date
            )
            
            commits.append(commit)
        }
        
        let hasMore = try doc.select("a:contains(next)").first() != nil
        let nextOffset = extractNextOffset(from: html)
        
        return CommitListResult(
            commits: commits,
            hasMore: hasMore,
            nextOffset: nextOffset
        )
    }
    
    private func extractSHA(from href: String) -> String? {
        if let range = href.range(of: "id=") {
            let sha = String(href[range.upperBound...])
            return sha.isEmpty ? nil : sha
        }
        return nil
    }
    
    private func parseAuthor(from text: String) -> (name: String, email: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let emailStart = trimmed.firstIndex(of: "<"),
           let emailEnd = trimmed.firstIndex(of: ">") {
            let name = String(trimmed[..<emailStart]).trimmingCharacters(in: .whitespaces)
            let email = String(trimmed[trimmed.index(after: emailStart)..<emailEnd])
            return (name, email)
        }
        
        return (trimmed, nil)
    }
    
    private func extractNextOffset(from html: String) -> Int? {
        guard let range = html.range(of: "ofs=") else { return nil }
        let afterOfs = String(html[range.upperBound...])
        let numberString = afterOfs.prefix(while: { $0.isNumber })
        return Int(numberString)
    }
}
