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
    
    public override init() {
        super.init()
    }
    
    public func parse(html: String) throws -> [DiffFile] {
        let doc = try parseDocument(html)
        
        // Check if this is a formatted diff view or raw patch
        if let diffContent = try doc.select("div.content").first() {
            return try parseFormattedDiff(doc: doc)
        } else {
            // Parse as raw patch text
            return parsePatchText(html)
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
    
    private func parseDiffTable(_ table: Element) throws -> DiffFile? {
        // cgit uses tables for diff display
        var lines: [DiffLine] = []
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
        
        // Extract file name from somewhere in the table
        let fileName = "unknown" // Would need to find where cgit puts this
        return DiffFile(oldPath: nil, newPath: fileName, changeType: .modified, hunks: hunks)
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
        let parts = header.components(separatedBy: " ")
        var oldPath: String?
        var newPath = "unknown"
        var changeType: DiffFile.ChangeType = .modified
        
        if parts.count >= 4 {
            oldPath = String(parts[2].dropFirst(2)) // Remove "a/"
            newPath = String(parts[3].dropFirst(2)) // Remove "b/"
            
            if header.contains("new file") {
                changeType = .added
            } else if header.contains("deleted file") {
                changeType = .deleted
            } else if header.contains("rename") {
                changeType = .renamed
            }
        }
        
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