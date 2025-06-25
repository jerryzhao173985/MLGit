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
            case "author":
                // Author cell contains name and email
                let authorText = try td.text()
                (authorName, authorEmail) = parseNameEmail(authorText)
                
                // Date is in the second td with class 'right'
                if let dateCell = try row.select("td.right").first() {
                    let dateText = try dateCell.text()
                    authorDate = parseDate(dateText) ?? Date()
                }
                
            case "committer":
                let committerText = try td.text()
                (committerName, committerEmail) = parseNameEmail(committerText)
                
                if let dateCell = try row.select("td.right").first() {
                    let dateText = try dateCell.text()
                    committerDate = parseDate(dateText)
                }
                
            case "commit":
                // Extract SHA from the link
                if let shaLink = try td.select("a").first() {
                    sha = try shaLink.text()
                } else {
                    // Sometimes SHA is in the td.oid directly
                    sha = try td.text()
                }
                
            case "parent":
                if let parentLink = try td.select("a").first() {
                    let parentSha = try parentLink.text()
                    parents.append(parentSha)
                }
                
            case "tree":
                if let treeLink = try td.select("a").first() {
                    tree = try treeLink.text()
                } else {
                    tree = try td.text()
                }
                
            default:
                break
            }
        }
        
        // Extract commit message
        let messageElement = try doc.select("div.commit-subject").first()
        let message = try messageElement?.text() ?? ""
        
        // Extract full commit message including body
        var fullMessage = message
        if let msgBody = try doc.select("div.commit-msg").first() {
            let bodyText = try msgBody.text()
            if !bodyText.isEmpty && bodyText != message {
                fullMessage = bodyText
            }
        }
        
        // Extract Change-Id if present
        var changeId: String?
        if fullMessage.contains("Change-Id:") {
            let lines = fullMessage.components(separatedBy: "\n")
            for line in lines {
                if line.hasPrefix("Change-Id:") {
                    changeId = line.replacingOccurrences(of: "Change-Id:", with: "")
                        .trimmingCharacters(in: .whitespaces)
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
            message: fullMessage,
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
        // Look for diffstat-summary div
        if let diffstatSummary = try doc.select("div.diffstat-summary").first() {
            let text = try diffstatSummary.text()
            
            // Parse "X files changed, Y insertions, Z deletions"
            var filesChanged = 0
            var insertions = 0
            var deletions = 0
            
            // Extract files changed
            if let filesMatch = text.range(of: #"(\d+)\s+files?\s+changed"#, options: .regularExpression) {
                let filesText = String(text[filesMatch])
                let numbers = filesText.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap { Int($0) }
                if let firstNumber = numbers.first {
                    filesChanged = firstNumber
                }
            }
            
            // Extract insertions
            if let insertMatch = text.range(of: #"(\d+)\s+insertions?"#, options: .regularExpression) {
                let insertText = String(text[insertMatch])
                let numbers = insertText.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap { Int($0) }
                if let firstNumber = numbers.first {
                    insertions = firstNumber
                }
            }
            
            // Extract deletions
            if let deleteMatch = text.range(of: #"(\d+)\s+deletions?"#, options: .regularExpression) {
                let deleteText = String(text[deleteMatch])
                let numbers = deleteText.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .compactMap { Int($0) }
                if let firstNumber = numbers.first {
                    deletions = firstNumber
                }
            }
            
            if filesChanged > 0 {
                return DiffStats(
                    filesChanged: filesChanged,
                    insertions: insertions,
                    deletions: deletions
                )
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
                
                // Expected structure: mode | filename | stats | graph
                guard cells.count >= 3 else { continue }
                
                // Mode cell (e.g., "-rw-r--r--")
                let modeCell = cells[0]
                let modeText = try modeCell.text()
                let changeType = parseChangeType(modeText)
                
                // Filename cell with update class
                let filenameCell = cells[1]
                if let fileLink = try filenameCell.select("a").first() {
                    let path = try fileLink.text()
                    
                    // Stats cell (e.g., "12" for total lines changed)
                    let statsCell = cells[2]
                    let statsText = try statsCell.text()
                    let totalChanges = Int(statsText) ?? 0
                    
                    // For cgit, we don't get separate add/delete counts in the table
                    // We'd need to parse the actual diff for that
                    let file = GitChangedFile(
                        path: path,
                        changeType: changeType,
                        additions: totalChanges, // Approximation
                        deletions: 0
                    )
                    files.append(file)
                }
            }
        }
        
        return files
    }
    
    private func parseChangeType(_ mode: String) -> GitChangedFile.ChangeType {
        // cgit uses mode strings or classes to indicate file status
        if mode.contains("new") || mode == "new" {
            return .added
        } else if mode.contains("del") || mode == "deleted" {
            return .deleted
        } else if mode.contains("rename") {
            return .renamed
        } else if mode.contains("copy") {
            return .copied
        } else {
            return .modified
        }
    }
}