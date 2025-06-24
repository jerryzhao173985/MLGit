import Foundation
import SwiftSoup

public struct CommitDetailInfo {
    public let sha: String
    public let message: String
    public let authorName: String
    public let authorEmail: String?
    public let authorDate: Date
    public let committerName: String?
    public let committerEmail: String?
    public let committerDate: Date?
    public let parents: [String]
    public let tree: String
    public let changeId: String?
    public let diffStats: DiffStats?
    public let changedFiles: [GitChangedFile]
    
    public init(sha: String, message: String, authorName: String, authorEmail: String?, authorDate: Date,
                committerName: String?, committerEmail: String?, committerDate: Date?,
                parents: [String], tree: String, changeId: String?, diffStats: DiffStats?, changedFiles: [GitChangedFile]) {
        self.sha = sha
        self.message = message
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.authorDate = authorDate
        self.committerName = committerName
        self.committerEmail = committerEmail
        self.committerDate = committerDate
        self.parents = parents
        self.tree = tree
        self.changeId = changeId
        self.diffStats = diffStats
        self.changedFiles = changedFiles
    }
}

public struct DiffStats {
    public let filesChanged: Int
    public let insertions: Int
    public let deletions: Int
    
    public init(filesChanged: Int, insertions: Int, deletions: Int) {
        self.filesChanged = filesChanged
        self.insertions = insertions
        self.deletions = deletions
    }
}

public struct GitChangedFile {
    public let path: String
    public let changeType: ChangeType
    public let additions: Int
    public let deletions: Int
    
    public enum ChangeType: String {
        case added = "A"
        case modified = "M"
        case deleted = "D"
        case renamed = "R"
        case copied = "C"
    }
    
    public init(path: String, changeType: ChangeType, additions: Int, deletions: Int) {
        self.path = path
        self.changeType = changeType
        self.additions = additions
        self.deletions = deletions
    }
}

public class CommitDetailParser: BaseParser, HTMLParserProtocol {
    public typealias Output = CommitDetailInfo
    
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
    
    public func parse(html: String) throws -> CommitDetailInfo {
        let doc = try parseDocument(html)
        
        // Extract commit info from the commit-info table
        guard let commitInfoTable = try doc.select("table.commit-info").first() else {
            throw ParserError.missingElement(selector: "table.commit-info")
        }
        
        var sha = ""
        var authorName = ""
        var authorEmail: String?
        var authorDate = Date()
        var committerName: String?
        var committerEmail: String?
        var committerDate: Date?
        var parents: [String] = []
        var tree = ""
        
        // Parse commit info rows
        let rows = try commitInfoTable.select("tr").array()
        for row in rows {
            guard let th = try row.select("th").first(),
                  let td = try row.select("td").first() else { continue }
            
            let label = try th.text().lowercased()
            
            switch label {
            case "commit":
                sha = try td.select("a").first()?.text() ?? ""
            case "author":
                let authorText = try td.text()
                (authorName, authorEmail) = parseNameEmail(authorText)
                if let dateCell = try row.select("td.right").first() {
                    authorDate = parseDate(try dateCell.text()) ?? Date()
                }
            case "committer":
                let committerText = try td.text()
                (committerName, committerEmail) = parseNameEmail(committerText)
                if let dateCell = try row.select("td.right").first() {
                    committerDate = parseDate(try dateCell.text())
                }
            case "parent":
                if let parentLink = try td.select("a").first() {
                    parents.append(try parentLink.text())
                }
            case "tree":
                tree = try td.select("a").first()?.text() ?? ""
            default:
                break
            }
        }
        
        // Extract commit message
        let message = try doc.select("div.commit-msg").first()?.text() ?? ""
        
        // Extract Change-Id if present
        var changeId: String?
        if message.contains("Change-Id:") {
            let lines = message.components(separatedBy: "\n")
            for line in lines {
                if line.hasPrefix("Change-Id:") {
                    changeId = line.replacingOccurrences(of: "Change-Id:", with: "").trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        
        // Parse diff stats
        let diffStats = try parseDiffStats(doc: doc)
        
        // Parse changed files
        let changedFiles = try parseChangedFiles(doc: doc)
        
        return CommitDetailInfo(
            sha: sha,
            message: message,
            authorName: authorName,
            authorEmail: authorEmail,
            authorDate: authorDate,
            committerName: committerName,
            committerEmail: committerEmail,
            committerDate: committerDate,
            parents: parents,
            tree: tree,
            changeId: changeId,
            diffStats: diffStats,
            changedFiles: changedFiles
        )
    }
    
    private func parseNameEmail(_ text: String) -> (name: String, email: String?) {
        // Format: "Name <email@example.com>"
        if let ltIndex = text.firstIndex(of: "<"),
           let gtIndex = text.firstIndex(of: ">"),
           ltIndex < gtIndex {
            let name = String(text[..<ltIndex]).trimmingCharacters(in: .whitespaces)
            let email = String(text[text.index(after: ltIndex)..<gtIndex])
            return (name, email)
        }
        return (text.trimmingCharacters(in: .whitespaces), nil)
    }
    
    private func parseDate(_ text: String) -> Date? {
        return dateFormatter.date(from: text)
    }
    
    private func parseDiffStats(doc: Document) throws -> DiffStats? {
        // Look for diffstat summary
        if let diffstatSummary = try doc.select("div.diffstat-summary").first() {
            let text = try diffstatSummary.text()
            // Parse "X files changed, Y insertions, Z deletions"
            let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            
            if numbers.count >= 3 {
                return DiffStats(filesChanged: numbers[0], insertions: numbers[1], deletions: numbers[2])
            }
        }
        return nil
    }
    
    private func parseChangedFiles(doc: Document) throws -> [GitChangedFile] {
        var files: [GitChangedFile] = []
        
        // Look for diffstat table
        if let diffstatTable = try doc.select("table.diffstat").first() {
            let rows = try diffstatTable.select("tr").array()
            
            for row in rows {
                let cells = try row.select("td").array()
                guard cells.count >= 3 else { continue }
                
                // First cell has the mode/change type
                let modeText = try cells[0].text()
                let changeType = parseChangeType(modeText)
                
                // Second cell has the file path
                if let fileLink = try cells[1].select("a").first() {
                    let path = try fileLink.text()
                    
                    // Third cell has the stats
                    let statsText = try cells[2].text()
                    let (additions, deletions) = parseFileStats(statsText)
                    
                    let file = GitChangedFile(
                        path: path,
                        changeType: changeType,
                        additions: additions,
                        deletions: deletions
                    )
                    files.append(file)
                }
            }
        }
        
        return files
    }
    
    private func parseChangeType(_ mode: String) -> GitChangedFile.ChangeType {
        if mode.contains("new") {
            return .added
        } else if mode.contains("deleted") {
            return .deleted
        } else if mode.contains("renamed") {
            return .renamed
        } else {
            return .modified
        }
    }
    
    private func parseFileStats(_ text: String) -> (additions: Int, deletions: Int) {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        
        if numbers.count >= 2 {
            return (numbers[0], numbers[1])
        }
        return (0, 0)
    }
}