import Foundation

struct Repository: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let description: String?
    let readme: String?
    let defaultBranch: String
    let lastUpdate: Date?
    
    var isStarred: Bool = false
    var isWatched: Bool = false
    var isPinned: Bool = false
    
    var fullURL: URL {
        URL(string: "https://git.mlplatform.org/\(path)")!
    }
}

struct Branch: Identifiable, Codable {
    let id: String
    let name: String
    let lastCommitSHA: String?
    let lastCommitMessage: String?
    let lastCommitDate: Date?
}

struct Tag: Identifiable, Codable {
    let id: String
    let name: String
    let commitSHA: String
    let taggerName: String?
    let taggerDate: Date?
    let message: String?
}