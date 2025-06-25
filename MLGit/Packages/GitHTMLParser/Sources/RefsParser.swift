import Foundation
import SwiftSoup

public struct RefInfo {
    public let name: String
    public let commitSHA: String
    public let commitMessage: String?
    public let authorName: String?
    public let date: Date?
    public let type: RefType
    
    public enum RefType {
        case branch
        case tag
    }
    
    public init(name: String, commitSHA: String, commitMessage: String?, authorName: String?, date: Date?, type: RefType) {
        self.name = name
        self.commitSHA = commitSHA
        self.commitMessage = commitMessage
        self.authorName = authorName
        self.date = date
        self.type = type
    }
}

public struct RefsResult {
    public let branches: [RefInfo]
    public let tags: [RefInfo]
    
    public init(branches: [RefInfo], tags: [RefInfo]) {
        self.branches = branches
        self.tags = tags
    }
}

public class RefsParser: BaseParser, HTMLParserProtocol {
    public typealias Output = RefsResult
    
    public init() {
        super.init(parserName: "RefsParser")
    }
    
    public func parse(html: String) throws -> RefsResult {
        let doc = try parseDocument(html)
        
        var branches: [RefInfo] = []
        var tags: [RefInfo] = []
        
        // Look for the main content table
        let tables = try doc.select("table.list.nowrap").array()
        
        // cgit refs page has a single table with both branches and tags
        if let mainTable = tables.first {
            let rows = try mainTable.select("tr").array()
            var currentSection: RefInfo.RefType?
            
            for row in rows {
                // Check if this is a header row
                if try row.hasClass("nohover") {
                    if let th = try row.select("th").first() {
                        let headerText = try th.text().lowercased()
                        if headerText == "branch" {
                            currentSection = .branch
                        } else if headerText == "tag" {
                            currentSection = .tag
                        }
                    }
                    continue
                }
                
                // Skip rows with empty cells
                let cells = try row.select("td").array()
                if cells.isEmpty {
                    continue
                }
                
                // Skip single cell rows with empty text
                if cells.count == 1 {
                    let text = try cells[0].text()
                    if text.isEmpty {
                        continue
                    }
                }
                
                // Parse data row based on current section
                if let section = currentSection {
                    if let ref = try parseRefRow(row, type: section) {
                        switch section {
                        case .branch:
                            branches.append(ref)
                        case .tag:
                            tags.append(ref)
                        }
                    }
                }
            }
        }
        
        return RefsResult(branches: branches, tags: tags)
    }
    
    private func parseRefRow(_ row: Element, type: RefInfo.RefType) throws -> RefInfo? {
        let cells = try row.select("td").array()
        
        // Expected structure varies between branches and tags
        if type == .branch {
            // Branch row: Name | Commit message | Author | Age
            guard cells.count >= 4 else { return nil }
            
            let nameCell = cells[0]
            let messageCell = cells[1]
            let authorCell = cells[2]
            let ageCell = cells[3]
            
            guard let nameLink = try nameCell.select("a").first() else { return nil }
            let name = try nameLink.text()
            
            let messageLink = try messageCell.select("a").first()
            let commitMessage = try messageLink?.text()
            
            // Extract SHA from commit message link
            let href = try messageLink?.attr("href") ?? ""
            let commitSHA = extractSHA(from: href)
            
            let authorName = try authorCell.text()
            let date = try extractDateFromAgeCell(ageCell)
            
            return RefInfo(
                name: name,
                commitSHA: commitSHA,
                commitMessage: commitMessage,
                authorName: authorName,
                date: date,
                type: type
            )
            
        } else {
            // Tag row: Name | Download | Author | Age
            guard cells.count >= 4 else { return nil }
            
            let nameCell = cells[0]
            let downloadCell = cells[1]
            let authorCell = cells[2]
            let ageCell = cells[3]
            
            guard let nameLink = try nameCell.select("a").first() else { return nil }
            let name = try nameLink.text()
            
            // For tags, extract SHA from download link
            let downloadLink = try downloadCell.select("a").first()
            let downloadText = try downloadLink?.text() ?? ""
            let commitSHA = extractSHAFromCommitText(downloadText)
            
            let authorName = try authorCell.text()
            let date = try extractDateFromAgeCell(ageCell)
            
            return RefInfo(
                name: name,
                commitSHA: commitSHA,
                commitMessage: nil, // Tags don't show commit message in refs view
                authorName: authorName,
                date: date,
                type: type
            )
        }
    }
    
    private func extractSHA(from href: String) -> String {
        // href format: "/tosa/reference_model.git/commit/?id=SHA" or "?h=branch"
        if let idRange = href.range(of: "id=") {
            let sha = String(href[href.index(idRange.upperBound, offsetBy: 0)...])
            if let ampIndex = sha.firstIndex(of: "&") {
                return String(sha[..<ampIndex])
            }
            return sha
        }
        return ""
    }
    
    private func extractSHAFromCommitText(_ text: String) -> String {
        // Format: "commit 120f815b2d..."
        if text.hasPrefix("commit ") {
            let sha = text.replacingOccurrences(of: "commit ", with: "")
                .replacingOccurrences(of: "...", with: "")
            return sha
        }
        return ""
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
}