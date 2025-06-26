import SwiftUI

/// Enhanced code view with sophisticated syntax highlighting
struct EnhancedCodeView: View {
    let content: String
    let language: String
    let fontSize: CGFloat
    let theme: String
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    
    @Environment(\.colorScheme) var colorScheme
    @State private var hoveredLine: Int? = nil
    
    private var lines: [String] {
        if content.isEmpty {
            return []
        }
        return content.components(separatedBy: .newlines)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        HStack(alignment: .top, spacing: 0) {
                            if showLineNumbers {
                                // Line number with hover effect
                                Text(String(format: "%4d", index + 1))
                                    .font(.system(size: fontSize - 2, design: .monospaced))
                                    .foregroundColor(hoveredLine == index ? .primary : .secondary)
                                    .frame(width: 50, alignment: .trailing)
                                    .background(
                                        hoveredLine == index ? 
                                        Color.gray.opacity(0.1) : 
                                        Color.clear
                                    )
                                    .padding(.trailing, 16)
                                    .onHover { isHovered in
                                        hoveredLine = isHovered ? index : nil
                                    }
                            }
                            
                            // Tokenized line content
                            tokenizedLineView(for: line, language: language)
                                .id(index)
                            
                            if !wrapLines {
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(.vertical, 2)
                        .background(
                            // Highlight search matches
                            highlightBackground(for: line, at: index)
                        )
                    }
                    
                    // Push content to top
                    Spacer(minLength: 0)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(backgroundColor)
        }
    }
    
    @ViewBuilder
    private func tokenizedLineView(for line: String, language: String) -> some View {
        let tokens = getTokens(for: line, language: language)
        
        if wrapLines {
            // Wrap lines for better readability on narrow screens
            Text(attributedString(from: tokens))
                .font(.system(size: fontSize, design: .monospaced))
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // No wrap - use horizontal scrolling
            TokenizedTextView(tokens: tokens, fontSize: fontSize)
        }
    }
    
    private func getTokens(for line: String, language: String) -> [Token] {
        switch language.lowercased() {
        case "python", "py":
            return EnhancedSyntaxHighlighter.tokenizePython(line)
        case "c", "cpp", "c++", "h", "hpp", "cc", "cxx":
            return EnhancedSyntaxHighlighter.tokenizeCpp(line)
        case "sh", "bash", "shell", "zsh":
            return EnhancedSyntaxHighlighter.tokenizeShell(line)
        case "gitignore":
            return EnhancedSyntaxHighlighter.tokenizeGitignore(line)
        case "javascript", "js", "typescript", "ts", "jsx", "tsx":
            return EnhancedSyntaxHighlighter.tokenizeJavaScript(line)
        case "swift":
            return EnhancedSyntaxHighlighter.tokenizeSwift(line)
        default:
            // For unsupported languages, treat as plain text
            return [Token(text: line.isEmpty ? " " : line, type: .plain)]
        }
    }
    
    private func attributedString(from tokens: [Token]) -> AttributedString {
        var result = AttributedString()
        
        for token in tokens {
            var part = AttributedString(token.text)
            part.font = .system(size: fontSize, design: .monospaced)
            part.foregroundColor = colorForToken(token)
            result += part
        }
        
        return result
    }
    
    private func colorForToken(_ token: Token) -> Color {
        switch token.type {
        case .keyword:
            return colorScheme == .dark ? Color(red: 0.68, green: 0.18, blue: 0.89) : Color(red: 0.68, green: 0.18, blue: 0.89)
        case .string:
            return colorScheme == .dark ? Color(red: 0.77, green: 0.10, blue: 0.09) : Color(red: 0.77, green: 0.10, blue: 0.09)
        case .comment:
            return colorScheme == .dark ? Color(red: 0.42, green: 0.47, blue: 0.53) : Color(red: 0.42, green: 0.47, blue: 0.53)
        case .number:
            return colorScheme == .dark ? Color(red: 0.13, green: 0.43, blue: 0.85) : Color(red: 0.13, green: 0.43, blue: 0.85)
        case .function:
            return colorScheme == .dark ? Color(red: 0.28, green: 0.68, blue: 0.86) : Color(red: 0.00, green: 0.46, blue: 0.96)
        case .variable:
            return colorScheme == .dark ? Color(red: 0.51, green: 0.77, blue: 0.64) : Color(red: 0.02, green: 0.60, blue: 0.30)
        case .operatorSymbol:
            return colorScheme == .dark ? Color(red: 0.86, green: 0.86, blue: 0.86) : Color(red: 0.36, green: 0.36, blue: 0.36)
        case .preprocessor:
            return colorScheme == .dark ? Color(red: 0.76, green: 0.49, blue: 0.29) : Color(red: 0.64, green: 0.21, blue: 0.00)
        case .type:
            return colorScheme == .dark ? Color(red: 0.42, green: 0.82, blue: 0.74) : Color(red: 0.00, green: 0.60, blue: 0.60)
        case .plain:
            return colorScheme == .dark ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.15, green: 0.15, blue: 0.15)
        }
    }
    
    private func highlightBackground(for line: String, at index: Int) -> Color {
        guard !searchText.isEmpty else { return Color.clear }
        
        if line.localizedCaseInsensitiveContains(searchText) {
            return Color.yellow.opacity(0.3)
        }
        
        return Color.clear
    }
    
    private var backgroundColor: Color {
        switch theme.lowercased() {
        case "github":
            return colorScheme == .dark ? Color(red: 0.06, green: 0.06, blue: 0.06) : Color(red: 0.98, green: 0.98, blue: 0.98)
        case "monokai":
            return Color(red: 0.15, green: 0.16, blue: 0.13)
        case "solarized":
            return colorScheme == .dark ? Color(red: 0.00, green: 0.17, blue: 0.21) : Color(red: 0.99, green: 0.96, blue: 0.89)
        default:
            return colorScheme == .dark ? Color(UIColor.systemBackground) : Color.white
        }
    }
}

/// Preview provider
struct EnhancedCodeView_Previews: PreviewProvider {
    static let samplePython = """
    # Python example
    import os
    import sys
    from typing import List, Dict
    
    class DataProcessor:
        def __init__(self, config: Dict[str, any]):
            self.config = config
            self.data = []
        
        def process_file(self, filename: str) -> List[str]:
            \"\"\"Process a single file and return results.\"\"\"
            results = []
            with open(filename, 'r') as f:
                for line in f:
                    if line.strip():  # Skip empty lines
                        results.append(self._transform(line))
            return results
        
        def _transform(self, text: str) -> str:
            # Apply transformations
            return text.upper().strip()
    
    if __name__ == "__main__":
        processor = DataProcessor({"debug": True})
        files = sys.argv[1:]
        for file in files:
            print(f"Processing {file}...")
            results = processor.process_file(file)
            print(f"Found {len(results)} results")
    """
    
    static let sampleCpp = """
    #include <iostream>
    #include <vector>
    #include <string>
    #include <algorithm>
    
    // Template class for data processing
    template<typename T>
    class DataProcessor {
    private:
        std::vector<T> data;
        bool debug_mode;
        
    public:
        DataProcessor(bool debug = false) : debug_mode(debug) {}
        
        void add_item(const T& item) {
            data.push_back(item);
            if (debug_mode) {
                std::cout << "Added item: " << item << std::endl;
            }
        }
        
        size_t process() {
            // Sort and remove duplicates
            std::sort(data.begin(), data.end());
            auto last = std::unique(data.begin(), data.end());
            data.erase(last, data.end());
            
            return data.size();
        }
    };
    
    int main(int argc, char* argv[]) {
        DataProcessor<std::string> processor(true);
        
        for (int i = 1; i < argc; ++i) {
            processor.add_item(std::string(argv[i]));
        }
        
        size_t unique_count = processor.process();
        std::cout << "Unique items: " << unique_count << std::endl;
        
        return 0;
    }
    """
    
    static var previews: some View {
        Group {
            EnhancedCodeView(
                content: samplePython,
                language: "python",
                fontSize: 14,
                theme: "github",
                showLineNumbers: true,
                wrapLines: false,
                searchText: ""
            )
            .previewDisplayName("Python")
            
            EnhancedCodeView(
                content: sampleCpp,
                language: "cpp",
                fontSize: 14,
                theme: "monokai",
                showLineNumbers: true,
                wrapLines: false,
                searchText: ""
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("C++ Dark")
        }
    }
}