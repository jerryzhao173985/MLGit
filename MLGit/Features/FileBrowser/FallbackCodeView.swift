import SwiftUI

/// Ultimate fallback code view that always works
struct FallbackCodeView: View {
    let content: String
    let language: String
    let fontSize: CGFloat
    let theme: String
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    
    @Environment(\.colorScheme) var colorScheme
    
    private var lines: [String] {
        if content.isEmpty {
            return []
        }
        return content.components(separatedBy: .newlines)
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 0) {
                        if showLineNumbers {
                            // Line number
                            Text(String(format: "%4d", index + 1))
                                .font(.system(size: fontSize - 2, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.trailing, 16)
                        }
                        
                        // Line content with basic syntax coloring
                        if language == "gitignore" || language == "bash" || language == "sh" {
                            // Shell-like syntax
                            ShellSyntaxText(line: line, fontSize: fontSize)
                        } else if language == "python" || language == "py" {
                            // Python syntax
                            PythonSyntaxText(line: line, fontSize: fontSize)
                        } else if ["cpp", "c++", "c", "h", "hpp"].contains(language) {
                            // C/C++ syntax
                            CppSyntaxText(line: line, fontSize: fontSize)
                        } else {
                            // Plain text
                            Text(line.isEmpty ? " " : line)
                                .font(.system(size: fontSize, design: .monospaced))
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 2)
                }
                
                Spacer(minLength: 0) // Push to top
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(colorScheme == .dark ? Color(UIColor.systemBackground) : Color.white)
    }
}

// Basic syntax highlighting for shell/gitignore
struct ShellSyntaxText: View {
    let line: String
    let fontSize: CGFloat
    
    var body: some View {
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
            // Comment
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.gray)
        } else if line.contains("*") || line.contains("/") || line.contains("!") {
            // Pattern
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.blue)
        } else {
            Text(line.isEmpty ? " " : line)
                .font(.system(size: fontSize, design: .monospaced))
        }
    }
}

// Basic syntax highlighting for Python
struct PythonSyntaxText: View {
    let line: String
    let fontSize: CGFloat
    
    private let keywords = ["def", "class", "import", "from", "return", "if", "else", "elif", "for", "while", "in", "and", "or", "not", "True", "False", "None", "try", "except", "finally", "with", "as", "pass", "break", "continue"]
    
    var body: some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("#") {
            // Comment
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.gray)
        } else if trimmed.hasPrefix("\"\"\"") || trimmed.hasPrefix("'''") {
            // Docstring
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.green)
        } else if keywords.contains(where: { line.contains($0 + " ") || line.contains(" " + $0) }) {
            // Contains keyword - simple approach
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.purple)
        } else {
            Text(line.isEmpty ? " " : line)
                .font(.system(size: fontSize, design: .monospaced))
        }
    }
}

// Basic syntax highlighting for C/C++
struct CppSyntaxText: View {
    let line: String
    let fontSize: CGFloat
    
    private let keywords = ["void", "int", "float", "double", "char", "bool", "class", "struct", "public", "private", "protected", "return", "if", "else", "for", "while", "namespace", "using", "include", "define", "ifdef", "ifndef", "endif"]
    
    var body: some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("//") {
            // Single line comment
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.gray)
        } else if trimmed.hasPrefix("#") {
            // Preprocessor directive
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.orange)
        } else if keywords.contains(where: { line.contains($0 + " ") || line.contains(" " + $0) }) {
            // Contains keyword
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.purple)
        } else {
            Text(line.isEmpty ? " " : line)
                .font(.system(size: fontSize, design: .monospaced))
        }
    }
}