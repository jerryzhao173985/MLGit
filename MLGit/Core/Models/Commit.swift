import Foundation

struct CommitSummary: Identifiable, Codable {
    let id: String
    let sha: String
    let message: String
    let authorName: String
    let authorEmail: String?
    let date: Date
    let shortMessage: String
    
    var shortSHA: String {
        String(sha.prefix(7))
    }
    
    var displayDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CommitDetail: Identifiable, Codable {
    let id: String
    let sha: String
    let message: String
    let authorName: String
    let authorEmail: String?
    let authorDate: Date
    let committerName: String?
    let committerEmail: String?
    let committerDate: Date?
    let parents: [String]
    let tree: String
    let diffStats: DiffStats?
    let changedFiles: [ChangedFile]
}

struct DiffStats: Codable {
    let filesChanged: Int
    let insertions: Int
    let deletions: Int
}

struct ChangedFile: Identifiable, Codable {
    let id: String
    let path: String
    let oldPath: String?
    let changeType: ChangeType
    let additions: Int
    let deletions: Int
    
    enum ChangeType: String, Codable {
        case added = "A"
        case modified = "M"
        case deleted = "D"
        case renamed = "R"
        case copied = "C"
    }
}