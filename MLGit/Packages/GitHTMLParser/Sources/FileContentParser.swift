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
    
    public init() {
        super.init(parserName: "FileContentParser")
    }
    
    public func parse(html: String) throws -> FileContentInfo {
        let doc = try parseDocument(html)
        
        print("FileContentParser: Starting to parse file content")
        
        // HTML logging handled by the service layer
        
        // Extract file path from breadcrumb
        let path = try extractFilePath(doc: doc)
        print("FileContentParser: Extracted path: '\(path)'")
        
        // Check if file is binary
        if let binaryNotice = try? doc.select("div.bin-blob").first() {
            let noticeText = try binaryNotice.text()
            print("FileContentParser: Detected binary file")
            return FileContentInfo(
                path: path,
                content: noticeText,
                lineCount: 0,
                size: nil,
                isBinary: true
            )
        }
        
        // Look for the blob table
        let blobTables = try doc.select("table.blob").array()
        print("FileContentParser: Found \(blobTables.count) table.blob elements")
        
        // Also look for any table that might contain the content
        let allTables = try doc.select("table").array()
        print("FileContentParser: Found \(allTables.count) total tables")
        for table in allTables {
            let className = (try? table.className()) ?? "no-class"
            print("FileContentParser: Table class: '\(className)'")
        }
        
        guard let blobTable = blobTables.first else {
            // Try alternative: Look for a div.blob
            let blobDivs = try doc.select("div.blob").array()
            print("FileContentParser: Found \(blobDivs.count) div.blob elements")
            
            if let blobDiv = blobDivs.first {
                print("FileContentParser: Found div.blob instead of table.blob")
                let content = try extractContentFromDiv(blobDiv)
                return FileContentInfo(
                    path: path,
                    content: content,
                    lineCount: content.components(separatedBy: .newlines).count,
                    size: Int64(content.utf8.count),
                    isBinary: false
                )
            }
            
            // Try looking for pre elements directly
            let preElements = try doc.select("pre").array()
            print("FileContentParser: Found \(preElements.count) pre elements")
            if let pre = preElements.first {
                print("FileContentParser: Using first pre element as content")
                let content = try extractTextContent(from: pre)
                return FileContentInfo(
                    path: path,
                    content: content,
                    lineCount: content.components(separatedBy: .newlines).count,
                    size: Int64(content.utf8.count),
                    isBinary: false
                )
            }
            
            print("FileContentParser: No blob table, div, or pre found")
            throw ParserError.missingElement(selector: "table.blob, div.blob, or pre")
        }
        
        print("FileContentParser: Found blob table")
        
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
            print("FileContentParser: Found td.lines")
            if let pre = try linesCell.select("pre").first() {
                print("FileContentParser: Found pre element in td.lines")
                content = try extractTextContent(from: pre)
            } else {
                print("FileContentParser: No pre element, extracting text directly from td.lines")
                content = try linesCell.text()
            }
        }
        // Option 2: Look for pre element directly in the table
        else if let pre = try blobTable.select("pre").last() {
            print("FileContentParser: Found pre element directly in table")
            content = try extractTextContent(from: pre)
        }
        // Option 3: Look for td.lines without specific class
        else if let td = try blobTable.select("td").array().first(where: { td in
            // Find the td that's not line numbers
            let classes = (try? td.className()) ?? ""
            return !classes.contains("linenumbers") && !classes.contains("linenos")
        }) {
            print("FileContentParser: Found content td without specific class")
            if let pre = try td.select("pre").first() {
                content = try extractTextContent(from: pre)
            } else {
                content = try td.text()
            }
        }
        // Option 4: Get all text from the table excluding line numbers
        else {
            print("FileContentParser: Fallback - extracting from table rows")
            let rows = try blobTable.select("tr").array()
            var lines: [String] = []
            
            for row in rows {
                let cells = try row.select("td").array()
                // Skip line number cell (first cell)
                if cells.count > 1 {
                    let lineContent = try cells[1].text()
                    lines.append(lineContent)
                } else if cells.count == 1 {
                    // Single cell row might contain content
                    let cellClass = (try? cells[0].className()) ?? ""
                    if !cellClass.contains("linenumbers") {
                        lines.append(try cells[0].text())
                    }
                }
            }
            
            content = lines.joined(separator: "\n")
        }
        
        print("FileContentParser: Extracted content length: \(content.count) characters")
        
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
            let _ = try links.map { try $0.text() }.joined(separator: "/")
            
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
    
    private func extractContentFromDiv(_ div: Element) throws -> String {
        // Look for pre elements
        if let pre = try div.select("pre").first() {
            return try extractTextContent(from: pre)
        }
        
        // Look for code elements
        if let code = try div.select("code").first() {
            return try code.text()
        }
        
        // Last resort - get all text
        return try div.text()
    }
}