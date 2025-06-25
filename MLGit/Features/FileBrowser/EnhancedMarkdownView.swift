import SwiftUI
// Uncomment after adding the package:
// import MarkdownUI

/// Enhanced Markdown View using swift-markdown-ui
/// 
/// This view provides full GitHub Flavored Markdown support with:
/// - Tables, task lists, blockquotes
/// - Syntax highlighted code blocks
/// - Custom themes and styling
/// - Better performance through pre-parsing
///
/// To use this view, first add the swift-markdown-ui package:
/// https://github.com/gonzalezreal/swift-markdown-ui
struct EnhancedMarkdownView: View {
    let content: String
    let baseURL: URL?
    
    init(content: String, baseURL: URL? = nil) {
        self.content = content
        self.baseURL = baseURL
    }
    
    var body: some View {
        ScrollView {
            // MARK: - Using swift-markdown-ui
            // Uncomment after adding the package:
            /*
            Markdown(content, baseURL: baseURL)
                .markdownTheme(.gitHub)
                .markdownCodeSyntaxHighlighter(.splash(theme: .github()))
                .markdownTextStyle {
                    FontSize(16)
                }
                .markdownBlockStyle(\.heading1) { configuration in
                    configuration.label
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                .markdownBlockStyle(\.heading2) { configuration in
                    configuration.label
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                }
                .markdownBlockStyle(\.codeBlock) { configuration in
                    configuration.label
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }
                .markdownBlockStyle(\.blockquote) { configuration in
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.5))
                            .frame(width: 4)
                        configuration.label
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            */
            
            // MARK: - Fallback to existing implementation
            // Remove this section after adding swift-markdown-ui
            MarkdownView(content: content, fontSize: 16)
                .padding()
        }
    }
}

// MARK: - Theme Extensions
// Uncomment after adding the package:
/*
extension Theme {
    /// GitHub-style markdown theme
    static let gitHub = Theme()
        .text {
            ForegroundColor(.primary)
            FontSize(16)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(14)
            BackgroundColor(Color(.secondarySystemBackground))
        }
        .strong {
            FontWeight(.semibold)
        }
        .link {
            ForegroundColor(.accentColor)
            UnderlineStyle(.single)
        }
        .heading1 { configuration in
            configuration.label
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .heading2 { configuration in
            configuration.label
                .font(.title)
                .fontWeight(.semibold)
        }
        .heading3 { configuration in
            configuration.label
                .font(.title2)
                .fontWeight(.medium)
        }
        .table { configuration in
            configuration.label
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
    
    /// Dark theme optimized for code documentation
    static let codeDark = Theme()
        .text {
            ForegroundColor(.white)
            FontSize(16)
        }
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(14)
            BackgroundColor(Color(red: 0.11, green: 0.13, blue: 0.16))
            ForegroundColor(Color(red: 0.88, green: 0.88, blue: 0.88))
        }
        .heading1 { configuration in
            configuration.label
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.47, green: 0.84, blue: 1.0))
        }
}

// MARK: - Syntax Highlighter Configuration
extension CodeSyntaxHighlighter {
    static func gitHub() -> CodeSyntaxHighlighter {
        // Configure syntax highlighter with GitHub theme
        // This would use the actual implementation from swift-markdown-ui
        return .splash(theme: .github())
    }
    
    static func oneDarkPro() -> CodeSyntaxHighlighter {
        // Configure syntax highlighter with One Dark Pro theme
        return .splash(theme: .oneDarkPro())
    }
}
*/

// MARK: - Preview
struct EnhancedMarkdownView_Previews: PreviewProvider {
    static let sampleMarkdown = """
    # Enhanced Markdown Rendering
    
    This view provides **full GitHub Flavored Markdown** support.
    
    ## Features
    
    - ✅ Task lists
    - 📊 Tables
    - 🎨 Syntax highlighting
    - 📝 Blockquotes
    
    ### Code Example
    
    ```swift
    struct ContentView: View {
        var body: some View {
            Text("Hello, World!")
                .font(.largeTitle)
                .foregroundColor(.blue)
        }
    }
    ```
    
    ### Table Example
    
    | Feature | Status | Notes |
    |---------|--------|-------|
    | Markdown | ✅ | Full GFM support |
    | Themes | ✅ | Customizable |
    | Performance | ✅ | Pre-parsed |
    
    > **Note**: This is a blockquote with important information.
    > It can span multiple lines and include **formatted text**.
    
    ---
    
    [View Documentation](https://github.com/gonzalezreal/swift-markdown-ui)
    """
    
    static var previews: some View {
        NavigationView {
            EnhancedMarkdownView(content: sampleMarkdown)
                .navigationTitle("Enhanced Markdown")
        }
    }
}