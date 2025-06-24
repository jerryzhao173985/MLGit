import Foundation

struct Project: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let path: String
    let description: String?
    let lastActivity: Date?
    let category: String?
    
    var fullURL: URL {
        URL(string: "https://git.mlplatform.org/\(path)")!
    }
    
    var displayCategory: String {
        if let category = category, !category.isEmpty {
            return category
        }
        
        let components = path.split(separator: "/")
        if let first = components.first {
            return String(first)
        }
        return "Other"
    }
}