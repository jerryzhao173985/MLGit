import SwiftUI

// Simple, reliable code view without any syntax highlighting
struct SimpleCodeView: View {
    let content: String
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wrapLines: Bool
    
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
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 0) {
                            if showLineNumbers {
                                Text(String(format: "%4d", index + 1))
                                    .font(.system(size: fontSize - 2, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 16)
                            }
                            
                            Text(line.isEmpty ? " " : line)
                                .font(.system(size: fontSize, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(wrapLines ? nil : 1)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    Spacer(minLength: 0) // Push content to top
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}