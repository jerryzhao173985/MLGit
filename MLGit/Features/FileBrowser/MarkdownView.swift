import SwiftUI

// Enhanced Markdown View
// Note: To get full markdown rendering, add swift-markdown-ui package:
// https://github.com/gonzalezreal/swift-markdown-ui

struct MarkdownView: View {
    let content: String
    let fontSize: CGFloat
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Parse and render markdown content
                ForEach(parseMarkdownBlocks(content), id: \.id) { block in
                    renderBlock(block)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block.type {
        case .heading(let level):
            Text(block.content)
                .font(headingFont(for: level))
                .fontWeight(.bold)
                .padding(.top, level == 1 ? 8 : 4)
                .padding(.bottom, 4)
            
        case .paragraph:
            Text(attributedString(from: block.content))
                .font(.system(size: fontSize))
                .fixedSize(horizontal: false, vertical: true)
            
        case .codeBlock(let language):
            CodeBlockView(
                code: block.content,
                language: language,
                fontSize: fontSize - 2
            )
            
        case .list(let ordered):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(block.items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text(ordered ? "\(index + 1)." : "•")
                            .font(.system(size: fontSize))
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: ordered ? .trailing : .center)
                        
                        Text(attributedString(from: item))
                            .font(.system(size: fontSize))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
        case .blockquote:
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(width: 4)
                
                Text(block.content)
                    .font(.system(size: fontSize))
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding(.vertical, 4)
            
        case .horizontalRule:
            Divider()
                .padding(.vertical, 8)
            
        case .table:
            // Simple table rendering
            if let headers = block.tableHeaders, let rows = block.tableRows {
                VStack(alignment: .leading, spacing: 0) {
                    // Headers
                    HStack {
                        ForEach(headers, id: \.self) { header in
                            Text(header)
                                .font(.system(size: fontSize - 1, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                    
                    Divider()
                    
                    // Rows
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        HStack {
                            ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                                Text(rows[rowIndex][colIndex])
                                    .font(.system(size: fontSize - 1))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 6)
                        
                        if rowIndex < rows.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .system(size: fontSize + 10, weight: .bold)
        case 2: return .system(size: fontSize + 6, weight: .semibold)
        case 3: return .system(size: fontSize + 3, weight: .semibold)
        case 4: return .system(size: fontSize + 1, weight: .medium)
        case 5: return .system(size: fontSize, weight: .medium)
        case 6: return .system(size: fontSize - 1, weight: .medium)
        default: return .system(size: fontSize)
        }
    }
    
    private func attributedString(from markdown: String) -> AttributedString {
        var result = AttributedString(markdown)
        
        // Apply inline formatting
        applyInlineFormatting(&result, pattern: "\\*\\*(.+?)\\*\\*", weight: .bold)
        applyInlineFormatting(&result, pattern: "__(.+?)__", weight: .bold)
        applyInlineFormatting(&result, pattern: "\\*(.+?)\\*", italic: true)
        applyInlineFormatting(&result, pattern: "_(.+?)_", italic: true)
        applyInlineCode(&result)
        applyLinks(&result)
        
        return result
    }
    
    private func applyInlineFormatting(_ string: inout AttributedString, pattern: String, weight: Font.Weight? = nil, italic: Bool = false) {
        let text = String(string.characters)
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: text),
                  let contentRange = Range(match.range(at: 1), in: text) else { continue }
            
            let content = String(text[contentRange])
            var replacement = AttributedString(content)
            
            if let weight = weight {
                replacement.font = .system(size: fontSize, weight: weight)
            }
            if italic {
                replacement.font = .system(size: fontSize).italic()
            }
            
            if let attrRange = Range(match.range, in: string) {
                string.replaceSubrange(attrRange, with: replacement)
            }
        }
    }
    
    private func applyInlineCode(_ string: inout AttributedString) {
        let text = String(string.characters)
        guard let regex = try? NSRegularExpression(pattern: "`(.+?)`") else { return }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: text),
                  let contentRange = Range(match.range(at: 1), in: text) else { continue }
            
            let content = String(text[contentRange])
            var replacement = AttributedString(content)
            replacement.font = .system(size: fontSize - 1, design: .monospaced)
            replacement.backgroundColor = Color.secondary.opacity(0.1)
            
            if let attrRange = Range(match.range, in: string) {
                string.replaceSubrange(attrRange, with: replacement)
            }
        }
    }
    
    private func applyLinks(_ string: inout AttributedString) {
        let text = String(string.characters)
        guard let regex = try? NSRegularExpression(pattern: "\\[(.+?)\\]\\((.+?)\\)") else { return }
        
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: text),
                  let textRange = Range(match.range(at: 1), in: text),
                  let urlRange = Range(match.range(at: 2), in: text) else { continue }
            
            let linkText = String(text[textRange])
            let urlString = String(text[urlRange])
            
            var replacement = AttributedString(linkText)
            replacement.foregroundColor = .accentColor
            replacement.underlineStyle = .single
            
            if let url = URL(string: urlString) {
                replacement.link = url
            }
            
            if let attrRange = Range(match.range, in: string) {
                string.replaceSubrange(attrRange, with: replacement)
            }
        }
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
    let code: String
    let language: String?
    let fontSize: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language = language, !language.isEmpty {
                Text(language)
                    .font(.system(size: fontSize - 2))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: fontSize, design: .monospaced))
                    .padding(12)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Markdown Parser

struct MarkdownBlock {
    let id = UUID()
    let type: BlockType
    let content: String
    var items: [String] = []
    var tableHeaders: [String]?
    var tableRows: [[String]]?
    
    enum BlockType {
        case heading(level: Int)
        case paragraph
        case codeBlock(language: String?)
        case list(ordered: Bool)
        case blockquote
        case horizontalRule
        case table
    }
}

func parseMarkdownBlocks(_ markdown: String) -> [MarkdownBlock] {
    let lines = markdown.components(separatedBy: .newlines)
    var blocks: [MarkdownBlock] = []
    var currentBlock: MarkdownBlock?
    var i = 0
    
    while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Code block
        if trimmed.hasPrefix("```") {
            let language = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
            var codeLines: [String] = []
            i += 1
            
            while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                codeLines.append(lines[i])
                i += 1
            }
            
            blocks.append(MarkdownBlock(
                type: .codeBlock(language: language.isEmpty ? nil : language),
                content: codeLines.joined(separator: "\n")
            ))
        }
        
        // Heading
        else if let match = trimmed.firstMatch(of: /^(#{1,6})\s+(.+)$/) {
            let level = match.1.count
            let content = String(match.2)
            blocks.append(MarkdownBlock(type: .heading(level: level), content: content))
        }
        
        // Horizontal rule
        else if trimmed.matches(of: /^(-{3,}|_{3,}|\*{3,})$/).count > 0 {
            blocks.append(MarkdownBlock(type: .horizontalRule, content: ""))
        }
        
        // List
        else if trimmed.matches(of: /^(\d+\.|[-*+])\s+/).count > 0 {
            let ordered = trimmed.first?.isNumber ?? false
            var items: [String] = []
            
            while i < lines.count {
                let itemLine = lines[i]
                if let match = itemLine.firstMatch(of: /^(\d+\.|[-*+])\s+(.+)$/) {
                    items.append(String(match.2))
                    i += 1
                } else if !itemLine.trimmingCharacters(in: .whitespaces).isEmpty &&
                          itemLine.hasPrefix("  ") {
                    // Continuation of previous item
                    if !items.isEmpty {
                        items[items.count - 1] += " " + itemLine.trimmingCharacters(in: .whitespaces)
                    }
                    i += 1
                } else {
                    i -= 1
                    break
                }
            }
            
            var block = MarkdownBlock(type: .list(ordered: ordered), content: "")
            block.items = items
            blocks.append(block)
        }
        
        // Blockquote
        else if trimmed.hasPrefix(">") {
            var quoteLines: [String] = []
            
            while i < lines.count && lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                let content = lines[i].trimmingCharacters(in: .whitespaces)
                    .dropFirst()
                    .trimmingCharacters(in: .whitespaces)
                quoteLines.append(String(content))
                i += 1
            }
            i -= 1
            
            blocks.append(MarkdownBlock(
                type: .blockquote,
                content: quoteLines.joined(separator: " ")
            ))
        }
        
        // Table (simple detection)
        else if i + 1 < lines.count && lines[i + 1].contains("|") && lines[i + 1].contains("-") {
            // This is a simple table detector
            let headerLine = line
            let headers = headerLine.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            
            i += 2 // Skip separator line
            var rows: [[String]] = []
            
            while i < lines.count && lines[i].contains("|") {
                let cells = lines[i].split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                rows.append(cells)
                i += 1
            }
            i -= 1
            
            var block = MarkdownBlock(type: .table, content: "")
            block.tableHeaders = headers
            block.tableRows = rows
            blocks.append(block)
        }
        
        // Paragraph
        else if !trimmed.isEmpty {
            var paragraphLines: [String] = [trimmed]
            i += 1
            
            while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).isEmpty {
                let nextLine = lines[i].trimmingCharacters(in: .whitespaces)
                
                // Check if next line starts a new block
                if nextLine.hasPrefix("#") || nextLine.hasPrefix("```") ||
                   nextLine.hasPrefix("-") || nextLine.hasPrefix("*") ||
                   nextLine.hasPrefix(">") || nextLine.first?.isNumber ?? false {
                    i -= 1
                    break
                }
                
                paragraphLines.append(nextLine)
                i += 1
            }
            i -= 1
            
            blocks.append(MarkdownBlock(
                type: .paragraph,
                content: paragraphLines.joined(separator: " ")
            ))
        }
        
        i += 1
    }
    
    return blocks
}