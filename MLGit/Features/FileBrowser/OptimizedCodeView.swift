import SwiftUI
import Highlightr

struct OptimizedCodeView: View {
    let content: String
    let language: String
    let fontSize: CGFloat
    let theme: String
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    let highlightr: Highlightr?
    
    private var lines: [String] {
        if content.isEmpty {
            return []
        }
        return content.components(separatedBy: .newlines)
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            if lines.isEmpty {
                Text("No content to display")
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                // Just display plain text - no highlighting complications
                PlainCodeTextView(
                    lines: lines,
                    fontSize: fontSize,
                    showLineNumbers: showLineNumbers,
                    wrapLines: wrapLines,
                    searchText: searchText
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Plain Code Text View

struct PlainCodeTextView: View {
    let lines: [String]
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    
    var body: some View {
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
                    } else {
                        HighlightedText(
                            text: line.isEmpty ? " " : line,
                            searchText: searchText,
                            fontSize: fontSize
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(wrapLines ? nil : 1)
                    }
                }
            }
            
            Spacer(minLength: 0) // Push content to top
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

// MARK: - Highlighted Text for Search

struct HighlightedText: View {
    let text: String
    let searchText: String
    let fontSize: CGFloat
    
    var body: some View {
        let attributed = highlightedString()
        Text(AttributedString(attributed))
            .font(.system(size: fontSize, design: .monospaced))
    }
    
    private func highlightedString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        
        if !searchText.isEmpty {
            let searchOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
            var searchRange = text.startIndex..<text.endIndex
            
            while let range = text.range(of: searchText, options: searchOptions, range: searchRange) {
                let nsRange = NSRange(range, in: text)
                attributedString.addAttribute(
                    .backgroundColor,
                    value: UIColor.systemYellow.withAlphaComponent(0.5),
                    range: nsRange
                )
                searchRange = range.upperBound..<text.endIndex
            }
        }
        
        return attributedString
    }
}

// Empty stub to keep compatibility - actual implementation moved above
struct HighlightedTextView: UIViewRepresentable {
    let attributedString: NSAttributedString
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    let lines: [String]
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = attributedString
    }
}