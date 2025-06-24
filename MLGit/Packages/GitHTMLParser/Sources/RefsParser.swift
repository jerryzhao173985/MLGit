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
    
    public override init() {
        super.init()
    }
    
    public func parse(html: String) throws -> RefsResult {
        let doc = try parseDocument(html)
        
        // Find all tables with class containing 'list'
        let allTables = try doc.select("table").array()
        let tables = allTables.filter { element in
            (try? element.className().contains("list")) ?? false
        }
        var branches: [RefInfo] = []
        var tags: [RefInfo] = []
        
        for table in tables {
            let previousH3 = try table.previousElementSibling()
            let sectionTitle = try previousH3?.text() ?? ""
            
            let isBranchSection = sectionTitle.lowercased().contains("branch")
            let refs = try parseRefsTable(table, type: isBranchSection ? .branch : .tag)
            
            if isBranchSection {
                branches.append(contentsOf: refs)
            } else {
                tags.append(contentsOf: refs)
            }
        }
        
        return RefsResult(branches: branches, tags: tags)
    }
    
    private func parseRefsTable(_ table: Element, type: RefInfo.RefType) throws -> [RefInfo] {
        let rows = try table.select("tr").array()
        var refs: [RefInfo] = []
        
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            let cells = try row.select("td").array()
            guard cells.count >= 3 else { continue }
            
            let nameCell = cells[0]
            let commitCell = cells[1]
            let authorCell = cells.count > 2 ? cells[2] : nil
            let ageCell = cells.count > 3 ? cells[3] : nil
            
            guard let nameLink = try nameCell.select("a").first() else { continue }
            let name = try nameLink.text()
            
            let commitLink = try commitCell.select("a").first()
            let commitMessage = try commitLink?.text()
            let commitHref = try commitLink?.attr("href") ?? ""
            let commitSHA = extractSHA(from: commitHref) ?? ""
            
            let authorName = try authorCell?.text()
            let ageText = try ageCell?.text()
            let date = ageText.flatMap { parseDate(from: $0) }
            
            let ref = RefInfo(
                name: name,
                commitSHA: commitSHA,
                commitMessage: commitMessage,
                authorName: authorName,
                date: date,
                type: type
            )
            
            refs.append(ref)
        }
        
        return refs
    }
    
    private func extractSHA(from href: String) -> String? {
        if let range = href.range(of: "id=") {
            let sha = String(href[range.upperBound...])
            if let ampRange = sha.firstIndex(of: "&") {
                return String(sha[..<ampRange])
            }
            return sha.isEmpty ? nil : sha
        }
        return nil
    }
}
