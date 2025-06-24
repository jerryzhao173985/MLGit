import Foundation

struct Ref: Identifiable, Codable {
    let id: String
    let name: String
    let commitSHA: String
    let commitMessage: String?
    let authorName: String?
    let date: Date?
    let type: RefType
    
    enum RefType: String, Codable {
        case branch
        case tag
    }
}