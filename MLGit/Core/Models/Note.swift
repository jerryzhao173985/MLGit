import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    let commitSHA: String?
    let filePath: String?
    let repositoryPath: String
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let tags: [String]
    
    init(commitSHA: String? = nil, 
         filePath: String? = nil, 
         repositoryPath: String, 
         title: String, 
         content: String, 
         tags: [String] = []) {
        self.id = UUID()
        self.commitSHA = commitSHA
        self.filePath = filePath
        self.repositoryPath = repositoryPath
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = tags
    }
}