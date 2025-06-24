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
        
        guard let table = try doc.select("table.list").first() else {
            throw ParserError.missingElement(selector: "table.list")
        }
        
        let rows = try table.select("tr").array()
        var nodes: [TreeNode] = []
        
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            let cells = try row.select("td").array()
            guard cells.count >= 3 else { continue }
            
            let modeCell = cells[0]
            let nameCell = cells[1]
            let sizeCell = cells[2]
            
            let mode = try modeCell.text().trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let link = try nameCell.select("a").first() else { continue }
            let name = try link.text()
            let href = try link.attr("href")
            
            let nodeType = determineNodeType(from: mode, href: href)
            let path = extractPath(from: href) ?? name
            
            let sizeText = try sizeCell.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let size = parseSize(from: sizeText)
            
            let node = TreeNode(
                name: name,
                path: path,
                type: nodeType,
                mode: mode.isEmpty ? nil : mode,
                size: size
            )
            
            nodes.append(node)
        }
        
        return nodes
    }
    
    private func determineNodeType(from mode: String, href: String) -> TreeNode.NodeType {
        if mode.hasPrefix("d") || href.contains("/tree/") {
            return .directory
        } else if mode.hasPrefix("l") {
            return .symlink
        } else if mode.hasPrefix("m") || href.contains("submodule") {
            return .submodule
        } else {
            return .file
        }
    }
    
    private func extractPath(from href: String) -> String? {
        if let range = href.range(of: "path=") {
            let path = String(href[range.upperBound...])
            if let ampRange = path.firstIndex(of: "&") {
                return String(path[..<ampRange])
            }
            return path
        }
        return nil
    }
    
    private func parseSize(from text: String) -> Int64? {
        let cleanText = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        if let bytes = Int64(cleanText) {
            return bytes
        }
        
        let multipliers: [String: Int64] = [
            "K": 1024,
            "M": 1024 * 1024,
            "G": 1024 * 1024 * 1024
        ]
        
        for (suffix, multiplier) in multipliers {
            if cleanText.hasSuffix(suffix) {
                let numberPart = cleanText.dropLast()
                if let value = Double(numberPart) {
                    return Int64(value * Double(multiplier))
                }
            }
        }
        
        return nil
    }
}
