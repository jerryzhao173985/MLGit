import Foundation
import SwiftSoup

public struct FileContentInfo {
    public let path: String
    public let content: String
    public let lineCount: Int
    public let size: Int64?
    public let isBinary: Bool
    
    public init(path: String, content: String, lineCount: Int, size: Int64?, isBinary: Bool) {
        self.path = path
        self.content = content
        self.lineCount = lineCount
        self.size = size
        self.isBinary = isBinary
    }
}

public class FileContentParser: BaseParser, HTMLParserProtocol {
    public typealias Output = FileContentInfo
    
    public override init() {
        super.init()
    }
    
    public func parse(html: String) throws -> FileContentInfo {
        let doc = try parseDocument(html)
        
        // Extract file path from breadcrumb
        let path = try extractFilePath(doc: doc)
        
        // Check if file is binary
        if let binaryNotice = try? doc.select("div.bin-blob").first() {
            let noticeText = try binaryNotice.text()
            return FileContentInfo(
                path: path,
                content: noticeText,
                lineCount: 0,
                size: nil,
                isBinary: true
            )
        }
        
        // Look for the blob table
        guard let blobTable = try doc.select("table.blob").first() else {
            throw ParserError.missingElement(selector: "table.blob")
        }
        
        // Extract line numbers to get line count
        var lineCount = 0
        if let lineNumbers = try blobTable.select("td.linenumbers pre").first() {
            let links = try lineNumbers.select("a").array()
            lineCount = links.count
        }
        
        // Extract file content
        var content = ""
        
        // Try to find the content in different possible locations
        // Option 1: Look for td with class 'lines'
        if let linesCell = try blobTable.select("td.lines").first() {
            if let pre = try linesCell.select("pre").first() {
                content = try extractTextContent(from: pre)
            } else {
                content = try linesCell.text()
            }
        }
        // Option 2: Look for pre element directly in the table
        else if let pre = try blobTable.select("pre").last() {
            content = try extractTextContent(from: pre)
        }
        // Option 3: Get all text from the table excluding line numbers
        else {
            let rows = try blobTable.select("tr").array()
            var lines: [String] = []
            
            for row in rows {
                let cells = try row.select("td").array()
                // Skip line number cell (first cell)
                if cells.count > 1 {
                    let lineContent = try cells[1].text()
                    lines.append(lineContent)
                }
            }
            
            content = lines.joined(separator: "\n")
        }
        
        // Calculate size in bytes
        let size = Int64(content.utf8.count)
        
        return FileContentInfo(
            path: path,
            content: content,
            lineCount: lineCount > 0 ? lineCount : content.components(separatedBy: .newlines).count,
            size: size,
            isBinary: false
        )
    }
    
    private func extractFilePath(doc: Document) throws -> String {
        // Try to extract from breadcrumb path
        if let pathDiv = try? doc.select("div.path").first() {
            let links = try pathDiv.select("a").array()
            var pathComponents: [String] = []
            
            for link in links {
                let text = try link.text()
                if text != "root" && !text.isEmpty {
                    pathComponents.append(text)
                }
            }
            
            // The last non-link text might be the filename
            let fullText = try pathDiv.text()
            let linkTexts = try links.map { try $0.text() }.joined(separator: "/")
            
            if let lastSlash = fullText.lastIndex(of: "/") {
                let filename = String(fullText[fullText.index(after: lastSlash)...])
                if !filename.isEmpty {
                    pathComponents.append(filename)
                }
            }
            
            return pathComponents.joined(separator: "/")
        }
        
        // Fallback: try to get from page title
        if let title = try? doc.select("title").first()?.text() {
            // Title might be "filename - repository.git"
            if let dashIndex = title.firstIndex(of: "-") {
                return String(title[..<dashIndex]).trimmingCharacters(in: .whitespaces)
            }
        }
        
        return "unknown"
    }
    
    private func extractTextContent(from element: Element) throws -> String {
        // For syntax-highlighted code, we need to extract text while preserving structure
        var lines: [String] = []
        
        // Check if the content has line-by-line structure
        let divs = try element.select("div").array()
        if !divs.isEmpty {
            // Each div might be a line
            for div in divs {
                let lineText = try extractLineText(from: div)
                lines.append(lineText)
            }
        } else {
            // No divs, try to get direct text content
            // Preserve line breaks by getting HTML and converting
            let html = try element.html()
            let text = html
                .replacingOccurrences(of: "<br>", with: "\n")
                .replacingOccurrences(of: "<br/>", with: "\n")
                .replacingOccurrences(of: "<br />", with: "\n")
            
            // Remove remaining HTML tags
            let doc = try SwiftSoup.parse(text)
            return try doc.text()
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func extractLineText(from element: Element) throws -> String {
        // For syntax highlighted code, collect all text nodes
        var text = ""
        
        for node in element.getChildNodes() {
            if let textNode = node as? TextNode {
                text += textNode.text()
            } else if let element = node as? Element {
                // Recursively get text from child elements
                text += try element.text()
            }
        }
        
        return text
    }
}