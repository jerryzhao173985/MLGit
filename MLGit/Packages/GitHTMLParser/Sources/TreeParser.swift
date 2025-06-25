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
    
    public init() {
        super.init(parserName: "TreeParser")
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
            
            // Extract size first
            let sizeText = try sizeCell.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let size = parseSize(from: sizeText)
            
            // Determine node type from multiple strategies
            var nodeType = try determineNodeType(from: link, mode: mode, href: href)
            
            // Additional check: If we detected as file but size is empty/zero, might be directory
            if nodeType == .file && (size == nil || size == 0) && !mode.hasPrefix("-") {
                print("TreeParser: Re-evaluating '\(name)' - no size for supposed file")
                // Only override if we're not confident about file detection
                if !href.contains("/blob/") && !href.contains("/plain/") {
                    nodeType = .directory
                    print("TreeParser: Changed '\(name)' to directory due to missing size")
                }
            }
            
            // Extract path from name (for files in subdirectories)
            let path = name
            
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
        // Enhanced logging for debugging
        let classes = try link.className()
        let linkText = try link.text()
        
        print("TreeParser: Analyzing node '\(linkText)':")
        print("  - Classes: '\(classes)'")
        print("  - Mode: '\(mode)'")
        print("  - Href: '\(href)'")
        
        // Strategy 1: Check link classes (most reliable for cgit)
        if classes.contains("ls-dir") {
            print("  -> Detected as directory via ls-dir class")
            return .directory
        } else if classes.contains("ls-blob") {
            print("  -> Detected as file via ls-blob class")
            return .file
        }
        
        // Strategy 2: Check parent td element classes
        if let parentTd = link.parent() {
            let tdClasses = (try? parentTd.className()) ?? ""
            if tdClasses.contains("ls-dir") {
                print("  -> Detected as directory via parent td ls-dir class")
                return .directory
            } else if tdClasses.contains("ls-blob") {
                print("  -> Detected as file via parent td ls-blob class")
                return .file
            }
        }
        
        // Strategy 3: Mode-based detection (Unix file permissions)
        let trimmedMode = mode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMode.isEmpty && trimmedMode != "-" {
            let firstChar = trimmedMode.first ?? "-"
            switch firstChar {
            case "d":
                print("  -> Detected as directory via mode '\(trimmedMode)'")
                return .directory
            case "l":
                print("  -> Detected as symlink via mode '\(trimmedMode)'")
                return .symlink
            case "m":
                print("  -> Detected as submodule via mode '\(trimmedMode)'")
                return .submodule
            case "-":
                print("  -> Detected as file via mode '\(trimmedMode)'")
                return .file
            default:
                print("  -> Unknown mode prefix: '\(firstChar)'")
            }
        }
        
        // Strategy 4: URL pattern detection
        if href.contains("/tree/") {
            print("  -> Detected as directory via /tree/ in href")
            return .directory
        } else if href.contains("/blob/") {
            print("  -> Detected as file via /blob/ in href")
            return .file
        } else if href.contains("/plain/") {
            print("  -> Detected as file via /plain/ in href")
            return .file
        }
        
        // Strategy 5: File extension heuristic
        let filename = linkText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !filename.isEmpty {
            // Common directory patterns
            if filename == ".." || filename == "." {
                print("  -> Detected as directory via special name")
                return .directory
            }
            
            // Check for file extension
            let hasExtension = filename.contains(".") && 
                             !filename.hasPrefix(".") && 
                             !filename.hasSuffix(".")
            
            // Special cases for common extensionless files
            let commonFiles = ["README", "LICENSE", "NOTICE", "Makefile", "Dockerfile", "Jenkinsfile", "Vagrantfile"]
            let isCommonFile = commonFiles.contains(filename)
            
            if hasExtension || isCommonFile {
                print("  -> Likely a file based on name pattern: '\(filename)'")
                return .file
            } else if !filename.contains(".") {
                print("  -> Likely a directory (no extension): '\(filename)'")
                return .directory
            }
        }
        
        // Default: Assume file if we can't determine
        print("  -> Defaulting to file (no detection method matched)")
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