import SwiftUI

struct PlainTextView: View {
    let content: String
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    
    @State private var lines: [String] = []
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                let maxLineNumberWidth = String(lines.count).count
                
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 0) {
                        if showLineNumbers {
                            Text(String(format: "%\(maxLineNumberWidth)d", index + 1))
                                .font(.system(size: fontSize - 2, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.trailing, 12)
                        }
                        
                        if searchText.isEmpty {
                            Text(line.isEmpty ? " " : line)
                                .font(.system(size: fontSize, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(wrapLines ? nil : 1)
                                .textSelection(.enabled)
                        } else {
                            HighlightedTextLine(
                                text: line.isEmpty ? " " : line,
                                searchText: searchText,
                                fontSize: fontSize,
                                wrapLines: wrapLines
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                
                // Add some padding at the bottom
                Color.clear
                    .frame(height: 50)
            }
            .padding()
        }
        .onAppear {
            lines = content.components(separatedBy: .newlines)
        }
    }
}

// MARK: - Highlighted Text Line

struct HighlightedTextLine: View {
    let text: String
    let searchText: String
    let fontSize: CGFloat
    let wrapLines: Bool
    
    var body: some View {
        Text(highlightedAttributedString())
            .font(.system(size: fontSize, design: .monospaced))
            .lineLimit(wrapLines ? nil : 1)
            .textSelection(.enabled)
    }
    
    private func highlightedAttributedString() -> AttributedString {
        var attributedString = AttributedString(text)
        
        if !searchText.isEmpty {
            let searchOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
            var searchRange = text.startIndex..<text.endIndex
            
            while let range = text.range(of: searchText, options: searchOptions, range: searchRange) {
                if let lowerBound = AttributedString.Index(range.lowerBound, within: attributedString),
                   let upperBound = AttributedString.Index(range.upperBound, within: attributedString) {
                    let attributedRange = lowerBound..<upperBound
                    attributedString[attributedRange].backgroundColor = .yellow.opacity(0.3)
                }
                searchRange = range.upperBound..<text.endIndex
            }
        }
        
        return attributedString
    }
}