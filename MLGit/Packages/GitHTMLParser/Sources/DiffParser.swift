import Foundation
import SwiftSoup

public struct DiffFile {
    public let oldPath: String?
    public let newPath: String
    public let changeType: ChangeType
    public let hunks: [DiffHunk]
    
    public enum ChangeType: String {
        case added = "A"
        case modified = "M"
        case deleted = "D"
        case renamed = "R"
        case copied = "C"
    }
    
    public init(oldPath: String?, newPath: String, changeType: ChangeType, hunks: [DiffHunk]) {
        self.oldPath = oldPath
        self.newPath = newPath
        self.changeType = changeType
        self.hunks = hunks
    }
}

public struct DiffHunk {
    public let oldStart: Int
    public let oldCount: Int
    public let newStart: Int
    public let newCount: Int
    public let header: String
    public let lines: [DiffLine]
    
    public init(oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, header: String, lines: [DiffLine]) {
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.header = header
        self.lines = lines
    }
}

public struct DiffLine {
    public let type: LineType
    public let content: String
    public let oldLineNumber: Int?
    public let newLineNumber: Int?
    
    public enum LineType {
        case context
        case addition
        case deletion
        case noNewline
    }
    
    public init(type: LineType, content: String, oldLineNumber: Int? = nil, newLineNumber: Int? = nil) {
        self.type = type
        self.content = content
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
    }
}

public class DiffParser: BaseParser, HTMLParserProtocol {
    public typealias Output = [DiffFile]
    
    public init() {
        super.init(parserName: "DiffParser")
    }
    
    public func parse(html: String) throws -> [DiffFile] {
        let doc = try parseDocument(html)
        
        print("DiffParser: Starting to parse HTML document")
        
        // HTML logging handled by the service layer
        
        // Check if this is a formatted diff view or raw patch
        if let _ = try doc.select("div.content").first() {
            print("DiffParser: Found div.content, parsing as formatted diff")
            return try parseFormattedDiff(doc: doc)
        } else if html.contains("diff --git") {
            print("DiffParser: No div.content found, parsing as raw patch text")
            return parsePatchText(html)
        } else {
            print("DiffParser: Attempting to parse as cgit diff table")
            // Try parsing cgit's table-based diff format
            return try parseCgitDiff(doc: doc)
        }
    }
    
    private func parseFormattedDiff(doc: Document) throws -> [DiffFile] {
        var files: [DiffFile] = []
        
        // Look for diff tables or divs
        let diffSections = try doc.select("div.diff").array()
        
        for section in diffSections {
            if let file = try parseDiffSection(section) {
                files.append(file)
            }
        }
        
        // If no div.diff, look for table.diff
        if files.isEmpty {
            let diffTables = try doc.select("table.diff").array()
            for table in diffTables {
                if let file = try parseDiffTable(table) {
                    files.append(file)
                }
            }
        }
        
        return files
    }
    
    private func parseDiffSection(_ section: Element) throws -> DiffFile? {
        // Extract file path from header
        guard let header = try section.select("div.head").first() else { return nil }
        let headerText = try header.text()
        let (oldPath, newPath, changeType) = parseFileHeader(headerText)
        
        // Parse hunks
        var hunks: [DiffHunk] = []
        let hunkDivs = try section.select("div.hunk").array()
        
        for hunkDiv in hunkDivs {
            if let hunk = try parseHunk(hunkDiv) {
                hunks.append(hunk)
            }
        }
        
        return DiffFile(oldPath: oldPath, newPath: newPath, changeType: changeType, hunks: hunks)
    }
    
    private func parseCgitDiff(doc: Document) throws -> [DiffFile] {
        var files: [DiffFile] = []
        
        // Look for any table that might contain diff data
        let tables = try doc.select("table").array()
        print("DiffParser: Found \(tables.count) tables in cgit diff")
        
        for table in tables {
            // Skip navigation tables
            let className = (try? table.className()) ?? ""
            if className.contains("tabs") || className.contains("list") {
                continue
            }
            
            print("DiffParser: Checking table with class: '\(className)'")
            
            // Check if this table contains diff content
            let hasLineNumbers = try table.select("td.linenumbers").count > 0
            let hasHunkHeader = try table.select("tr.hunk").count > 0
            let hasDiffContent = try table.html().contains("+") || table.html().contains("-")
            
            if hasLineNumbers || hasHunkHeader || hasDiffContent {
                print("DiffParser: Found diff table (lineNumbers: \(hasLineNumbers), hunk: \(hasHunkHeader), diff: \(hasDiffContent))")
                if let file = try parseDiffTable(table) {
                    files.append(file)
                }
            }
        }
        
        // If no tables found, try looking for pre-formatted diff content
        if files.isEmpty {
            let preElements = try doc.select("pre").array()
            print("DiffParser: No diff tables found, checking \(preElements.count) pre elements")
            
            for pre in preElements {
                let content = try pre.text()
                if content.contains("diff --git") || content.contains("@@") {
                    print("DiffParser: Found diff content in pre element")
                    return parsePatchText(content)
                }
            }
        }
        
        return files
    }
    
    private func parseDiffTable(_ table: Element) throws -> DiffFile? {
        // cgit uses tables for diff display
        let rows = try table.select("tr").array()
        
        var currentHunk: DiffHunk?
        var hunkLines: [DiffLine] = []
        var hunks: [DiffHunk] = []
        
        for row in rows {
            let cells = try row.select("td").array()
            guard cells.count >= 3 else { continue }
            
            // Check if this is a hunk header
            if try row.hasClass("hunk") {
                // Save previous hunk
                if let hunk = currentHunk {
                    hunks.append(DiffHunk(
                        oldStart: hunk.oldStart,
                        oldCount: hunk.oldCount,
                        newStart: hunk.newStart,
                        newCount: hunk.newCount,
                        header: hunk.header,
                        lines: hunkLines
                    ))
                    hunkLines = []
                }
                
                // Parse new hunk header
                let hunkText = try cells[2].text()
                if let hunk = parseHunkHeader(hunkText) {
                    currentHunk = hunk
                }
            } else {
                // Parse diff line
                let oldLineNum = Int(try cells[0].text())
                let newLineNum = Int(try cells[1].text())
                let content = try cells[2].text()
                
                let lineType: DiffLine.LineType
                if try row.hasClass("add") {
                    lineType = .addition
                } else if try row.hasClass("del") {
                    lineType = .deletion
                } else {
                    lineType = .context
                }
                
                let line = DiffLine(
                    type: lineType,
                    content: content,
                    oldLineNumber: oldLineNum,
                    newLineNumber: newLineNum
                )
                hunkLines.append(line)
            }
        }
        
        // Add last hunk
        if let hunk = currentHunk {
            hunks.append(DiffHunk(
                oldStart: hunk.oldStart,
                oldCount: hunk.oldCount,
                newStart: hunk.newStart,
                newCount: hunk.newCount,
                header: hunk.header,
                lines: hunkLines
            ))
        }
        
        // Extract filename from the table or surrounding context
        let fileName = try extractFileName(from: table)
        return DiffFile(oldPath: nil, newPath: fileName, changeType: .modified, hunks: hunks)
    }
    
    private func extractFileName(from table: Element) throws -> String {
        // Strategy 1: Look for cgit's specific div.path breadcrumb
        if let doc = table.ownerDocument() {
            if let pathDiv = try doc.select("div.path").first() {
                let pathText = try pathDiv.text()
                print("DiffParser: Found cgit path div: '\(pathText)'")
                
                // Extract the file path from breadcrumb (e.g., "root / path / to / file.txt")
                let components = pathText
                    .replacingOccurrences(of: " / ", with: "/")
                    .split(separator: "/")
                    .dropFirst() // Remove "root" or repo name
                
                if !components.isEmpty {
                    let filePath = components.joined(separator: "/")
                    print("DiffParser: Extracted file path from breadcrumb: '\(filePath)'")
                    return filePath
                }
            }
            
            // Strategy 2: Look for filename in page title
            if let title = try doc.select("title").first() {
                let titleText = try title.text()
                print("DiffParser: Found title: '\(titleText)'")
                
                // cgit titles often have format: "filename - repo - cgit"
                if let firstDash = titleText.firstIndex(of: "-") {
                    let filename = titleText[..<firstDash].trimmingCharacters(in: .whitespaces)
                    if !filename.isEmpty && filename != "cgit" {
                        print("DiffParser: Extracted filename from title: '\(filename)'")
                        return filename
                    }
                }
            }
        }
        
        // Strategy 3: Look for div.header or any header before the table
        if let parent = table.parent() {
            // Check all previous siblings and parent's children for headers
            let allElements = try parent.children().array()
            if let tableIndex = allElements.firstIndex(of: table) {
                // Look backwards from the table
                for i in stride(from: tableIndex - 1, through: 0, by: -1) {
                    let element = allElements[i]
                    let tagName = element.tagName()
                    
                    if tagName == "div" || tagName.hasPrefix("h") {
                        let text = try element.text()
                        print("DiffParser: Found header element '\(tagName)': '\(text)'")
                        
                        if let filename = extractFileNameFromHeader(text) {
                            return filename
                        }
                    }
                }
            }
        }
        
        // Strategy 4: Look for links in the table that might contain the filename
        let links = try table.select("a").array()
        for link in links {
            let href = try link.attr("href")
            if href.contains("/blob/") || href.contains("/tree/") {
                print("DiffParser: Found file link: '\(href)'")
                
                // Extract path after blob/ or tree/
                if let range = href.range(of: "/blob/") {
                    let pathPart = String(href[range.upperBound...])
                    if let queryIndex = pathPart.firstIndex(of: "?") {
                        let path = String(pathPart[..<queryIndex])
                        if !path.isEmpty {
                            print("DiffParser: Extracted path from blob link: '\(path)'")
                            return path
                        }
                    }
                }
            }
        }
        
        // Default fallback
        print("DiffParser: Could not extract filename, using 'unknown'")
        return "unknown"
    }
    
    private func extractFileNameFromHeader(_ text: String) -> String? {
        // Common patterns in cgit headers:
        // "diff --git a/path/to/file b/path/to/file"
        // "path/to/file"
        // "--- a/path/to/file"
        // "+++ b/path/to/file"
        
        // Pattern 1: git diff format
        if text.contains("diff --git") {
            let pattern = #"diff --git a/(.*?) b/"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        
        // Pattern 2: --- or +++ format
        if text.hasPrefix("---") || text.hasPrefix("+++") {
            let components = text.split(separator: " ")
            if components.count >= 2 {
                let path = String(components[1])
                // Remove leading a/ or b/
                if path.hasPrefix("a/") || path.hasPrefix("b/") {
                    return String(path.dropFirst(2))
                }
                return path
            }
        }
        
        // Pattern 3: Just a path
        if !text.contains(" ") && text.contains("/") {
            return text
        }
        
        // Pattern 4: Extract last path component from any text
        let words = text.split(separator: " ")
        for word in words {
            if word.contains("/") && !word.hasPrefix("http") {
                let components = word.split(separator: "/")
                if let last = components.last {
                    return String(last)
                }
            }
        }
        
        return nil
    }
    
    private func parseHunk(_ hunkElement: Element) throws -> DiffHunk? {
        guard let header = try hunkElement.select("div.head").first() else { return nil }
        let headerText = try header.text()
        
        guard let hunk = parseHunkHeader(headerText) else { return nil }
        
        var lines: [DiffLine] = []
        let lineElements = try hunkElement.select("div.line").array()
        
        var oldLineNum = hunk.oldStart
        var newLineNum = hunk.newStart
        
        for lineElement in lineElements {
            let text = try lineElement.text()
            let lineType: DiffLine.LineType
            
            if text.hasPrefix("+") {
                lineType = .addition
                lines.append(DiffLine(type: lineType, content: String(text.dropFirst()), newLineNumber: newLineNum))
                newLineNum += 1
            } else if text.hasPrefix("-") {
                lineType = .deletion
                lines.append(DiffLine(type: lineType, content: String(text.dropFirst()), oldLineNumber: oldLineNum))
                oldLineNum += 1
            } else if text.hasPrefix(" ") {
                lineType = .context
                lines.append(DiffLine(type: lineType, content: String(text.dropFirst()), oldLineNumber: oldLineNum, newLineNumber: newLineNum))
                oldLineNum += 1
                newLineNum += 1
            } else if text.hasPrefix("\\") {
                lineType = .noNewline
                lines.append(DiffLine(type: lineType, content: text))
            }
        }
        
        return DiffHunk(
            oldStart: hunk.oldStart,
            oldCount: hunk.oldCount,
            newStart: hunk.newStart,
            newCount: hunk.newCount,
            header: headerText,
            lines: lines
        )
    }
    
    private func parsePatchText(_ text: String) -> [DiffFile] {
        var files: [DiffFile] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentFile: DiffFile?
        var currentHunk: DiffHunk?
        var hunkLines: [DiffLine] = []
        var hunks: [DiffHunk] = []
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            if line.hasPrefix("diff --git") {
                // Save previous file
                if let file = currentFile {
                    if let hunk = currentHunk {
                        hunks.append(DiffHunk(
                            oldStart: hunk.oldStart,
                            oldCount: hunk.oldCount,
                            newStart: hunk.newStart,
                            newCount: hunk.newCount,
                            header: hunk.header,
                            lines: hunkLines
                        ))
                    }
                    files.append(DiffFile(
                        oldPath: file.oldPath,
                        newPath: file.newPath,
                        changeType: file.changeType,
                        hunks: hunks
                    ))
                    hunks = []
                    hunkLines = []
                    currentHunk = nil
                }
                
                // Parse new file header
                let parts = line.components(separatedBy: " ")
                if parts.count >= 4 {
                    let oldPath = String(parts[2].dropFirst(2)) // Remove "a/"
                    let newPath = String(parts[3].dropFirst(2)) // Remove "b/"
                    currentFile = DiffFile(oldPath: oldPath, newPath: newPath, changeType: .modified, hunks: [])
                }
            } else if line.hasPrefix("@@") {
                // Save previous hunk
                if let hunk = currentHunk {
                    hunks.append(DiffHunk(
                        oldStart: hunk.oldStart,
                        oldCount: hunk.oldCount,
                        newStart: hunk.newStart,
                        newCount: hunk.newCount,
                        header: hunk.header,
                        lines: hunkLines
                    ))
                    hunkLines = []
                }
                
                // Parse hunk header
                currentHunk = parseHunkHeader(line)
            } else if line.hasPrefix("+") && !line.hasPrefix("+++") {
                hunkLines.append(DiffLine(type: .addition, content: String(line.dropFirst())))
            } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                hunkLines.append(DiffLine(type: .deletion, content: String(line.dropFirst())))
            } else if line.hasPrefix(" ") {
                hunkLines.append(DiffLine(type: .context, content: String(line.dropFirst())))
            } else if line.hasPrefix("\\") {
                hunkLines.append(DiffLine(type: .noNewline, content: line))
            }
            
            i += 1
        }
        
        // Save last file
        if let file = currentFile {
            if let hunk = currentHunk {
                hunks.append(DiffHunk(
                    oldStart: hunk.oldStart,
                    oldCount: hunk.oldCount,
                    newStart: hunk.newStart,
                    newCount: hunk.newCount,
                    header: hunk.header,
                    lines: hunkLines
                ))
            }
            files.append(DiffFile(
                oldPath: file.oldPath,
                newPath: file.newPath,
                changeType: file.changeType,
                hunks: hunks
            ))
        }
        
        return files
    }
    
    private func parseFileHeader(_ header: String) -> (oldPath: String?, newPath: String, changeType: DiffFile.ChangeType) {
        // Parse headers like "diff --git a/file.txt b/file.txt"
        print("DiffParser: Parsing file header: '\(header)'")
        
        var oldPath: String?
        var newPath = "unknown"
        var changeType: DiffFile.ChangeType = .modified
        
        // Try to extract paths using regex for more robust parsing
        if header.contains("diff --git") {
            // Pattern: diff --git a/path/to/file b/path/to/file
            let pattern = #"diff --git a/(.*?) b/(.*?)(?:\s|$)"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: header, range: NSRange(header.startIndex..., in: header)) {
                
                if let oldRange = Range(match.range(at: 1), in: header),
                   let newRange = Range(match.range(at: 2), in: header) {
                    oldPath = String(header[oldRange])
                    newPath = String(header[newRange])
                    print("DiffParser: Extracted paths - old: '\(oldPath ?? "nil")', new: '\(newPath)'")
                }
            }
        } else {
            // Fallback: Simple space-based parsing
            let parts = header.components(separatedBy: " ")
            if parts.count >= 4 {
                let oldCandidate = parts[2]
                let newCandidate = parts[3]
                
                // Remove a/ or b/ prefix if present
                if oldCandidate.hasPrefix("a/") {
                    oldPath = String(oldCandidate.dropFirst(2))
                } else {
                    oldPath = oldCandidate
                }
                
                if newCandidate.hasPrefix("b/") {
                    newPath = String(newCandidate.dropFirst(2))
                } else {
                    newPath = newCandidate
                }
            }
        }
        
        // Detect change type
        if header.contains("new file") {
            changeType = .added
            oldPath = nil // New files don't have an old path
        } else if header.contains("deleted file") {
            changeType = .deleted
        } else if header.contains("rename") {
            changeType = .renamed
        } else if header.contains("copy") {
            changeType = .copied
        }
        
        print("DiffParser: Final result - changeType: \(changeType), newPath: '\(newPath)'")
        return (oldPath, newPath, changeType)
    }
    
    private func parseHunkHeader(_ header: String) -> DiffHunk? {
        // Parse headers like "@@ -1,4 +1,6 @@ function name"
        let pattern = #"@@ -(\d+),?(\d+)? \+(\d+),?(\d+)? @@(.*)?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: header, range: NSRange(header.startIndex..., in: header)) else {
            return nil
        }
        
        let oldStart = Int((header as NSString).substring(with: match.range(at: 1))) ?? 1
        let oldCount = match.range(at: 2).location != NSNotFound ? Int((header as NSString).substring(with: match.range(at: 2))) ?? 1 : 1
        let newStart = Int((header as NSString).substring(with: match.range(at: 3))) ?? 1
        let newCount = match.range(at: 4).location != NSNotFound ? Int((header as NSString).substring(with: match.range(at: 4))) ?? 1 : 1
        
        return DiffHunk(
            oldStart: oldStart,
            oldCount: oldCount,
            newStart: newStart,
            newCount: newCount,
            header: header,
            lines: []
        )
    }
}