import Foundation

struct FileNode: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let type: NodeType
    let mode: String?
    let size: Int64?
    let lastCommit: CommitSummary?
    
    enum NodeType: String, Codable {
        case file
        case directory
        case symlink
        case submodule
    }
    
    var isDirectory: Bool {
        type == .directory || type == .submodule
    }
    
    var icon: String {
        switch type {
        case .directory:
            return "folder"
        case .file:
            return fileIcon(for: name)
        case .symlink:
            return "link"
        case .submodule:
            return "square.stack.3d.up"
        }
    }
    
    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift":
            return "swift"
        case "md", "markdown":
            return "doc.text"
        case "json", "yml", "yaml":
            return "doc.badge.gearshape"
        case "png", "jpg", "jpeg", "gif":
            return "photo"
        case "pdf":
            return "doc.richtext"
        default:
            return "doc"
        }
    }
}

struct FileContent: Codable {
    let path: String
    let content: String
    let size: Int64
    let encoding: String
    let isBinary: Bool
}