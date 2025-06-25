import Foundation
import SwiftSoup

public struct TreeNode {
    public let name: String
    public let path: String
    public let type: NodeType
    public let mode: String?
    public let size: Int64?
    
    public enum NodeType: String {
        case file = "file"
        case directory = "dir"
        case symlink = "link"
        case submodule = "submodule"
    }
    
    public init(name: String, path: String, type: NodeType, mode: String?, size: Int64?) {
        self.name = name
        self.path = path
        self.type = type
        self.mode = mode
        self.size = size
    }
}

public class TreeParser: BaseParser, HTMLParserProtocol {
    public typealias Output = [TreeNode]
    
    public override init() {
        super.init()
    }
    
    public func parse(html: String) throws -> [TreeNode] {
        let doc = try parseDocument(html)
        
        // Look for table with class 'list' (without nowrap for tree view)
        let tables = try doc.select("table.list").array()
        guard let table = tables.first else {
            throw ParserError.missingElement(selector: "table.list")
        }
        
        let rows = try table.select("tr").array()
        var nodes: [TreeNode] = []
        
        for row in rows {
            // Skip header row (has class 'nohover' and contains th elements)
            if try row.hasClass("nohover") && row.select("th").count > 0 {
                continue
            }
            
            let cells = try row.select("td").array()
            
            // Expected structure: Mode | Name | Size | Actions
            guard cells.count >= 3 else { continue }
            
            let modeCell = cells[0]
            let nameCell = cells[1]
            let sizeCell = cells[2]
            
            // Extract mode (e.g., "-rw-r--r--", "d---------")
            let mode = try modeCell.text().trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract name and href from link
            guard let link = try nameCell.select("a").first() else { continue }
            let name = try link.text()
            let href = try link.attr("href")
            
            // Determine node type from link classes and href
            let nodeType = try determineNodeType(from: link, mode: mode, href: href)
            
            // Extract path from name (for files in subdirectories)
            let path = name
            
            // Extract size
            let sizeText = try sizeCell.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let size = parseSize(from: sizeText)
            
            let node = TreeNode(
                name: name,
                path: path,
                type: nodeType,
                mode: mode.isEmpty || mode == "-" ? nil : mode,
                size: size
            )
            
            nodes.append(node)
        }
        
        return nodes
    }
    
    private func determineNodeType(from link: Element, mode: String, href: String) throws -> TreeNode.NodeType {
        // Check link classes first
        let classes = try link.className()
        
        if classes.contains("ls-dir") {
            return .directory
        } else if classes.contains("ls-blob") {
            return .file
        }
        
        // Fallback to mode-based detection
        if mode.hasPrefix("d") {
            return .directory
        } else if mode.hasPrefix("l") {
            return .symlink
        } else if mode.hasPrefix("m") {
            return .submodule
        }
        
        // Check href as last resort
        if href.contains("/tree/") && !href.contains("?") {
            return .directory
        }
        
        return .file
    }
    
    private func parseSize(from text: String) -> Int64? {
        // Clean the text
        let cleanText = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty or non-numeric for directories
        if cleanText.isEmpty || cleanText == "-" {
            return nil
        }
        
        // Try to parse as bytes
        if let bytes = Int64(cleanText) {
            return bytes
        }
        
        // Handle size with units (K, M, G)
        let multipliers: [String: Int64] = [
            "K": 1024,
            "KB": 1024,
            "M": 1024 * 1024,
            "MB": 1024 * 1024,
            "G": 1024 * 1024 * 1024,
            "GB": 1024 * 1024 * 1024
        ]
        
        for (suffix, multiplier) in multipliers {
            if cleanText.uppercased().hasSuffix(suffix) {
                let numberPart = String(cleanText.dropLast(suffix.count))
                if let value = Double(numberPart) {
                    return Int64(value * Double(multiplier))
                }
            }
        }
        
        return nil
    }
}