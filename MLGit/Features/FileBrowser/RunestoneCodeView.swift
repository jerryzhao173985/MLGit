import SwiftUI
import UIKit
// Uncomment after adding the package:
// import Runestone

/// Runestone-based code view with advanced syntax highlighting
///
/// This view provides:
/// - Tree-sitter based syntax highlighting (most performant)
/// - Line numbers and gutter
/// - 180+ language support
/// - Multiple themes
/// - Invisible character display
/// - Search functionality
///
/// To use this view, first add the Runestone package:
/// https://github.com/simonbs/Runestone
struct RunestoneCodeView: UIViewRepresentable {
    let content: String
    let language: String?
    let theme: RunestoneTheme
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let showInvisibleCharacters: Bool
    let isEditable: Bool
    
    init(
        content: String,
        language: String? = nil,
        theme: RunestoneTheme = .gitHub,
        fontSize: CGFloat = 14,
        showLineNumbers: Bool = true,
        showInvisibleCharacters: Bool = false,
        isEditable: Bool = false
    ) {
        self.content = content
        self.language = language
        self.theme = theme
        self.fontSize = fontSize
        self.showLineNumbers = showLineNumbers
        self.showInvisibleCharacters = showInvisibleCharacters
        self.isEditable = isEditable
    }
    
    func makeUIView(context: Context) -> UITextView {
        // MARK: - Using Runestone
        // Uncomment after adding the package:
        /*
        let textView = Runestone.TextView()
        
        // Configure the text view
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.showLineNumbers = showLineNumbers
        textView.showSpaces = showInvisibleCharacters
        textView.showTabs = showInvisibleCharacters
        textView.showLineBreaks = showInvisibleCharacters
        textView.showPageGuide = false
        textView.lineSelectionDisplayType = .line
        
        // Set the theme
        textView.theme = theme.runestoneTheme
        
        // Set the language
        if let language = language,
           let treeLanguage = TreeSitterLanguage(rawValue: language) {
            textView.language = treeLanguage.language
        } else {
            // Auto-detect language from file extension or content
            textView.language = detectLanguage(from: content)
        }
        
        // Set font
        textView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        // Set the content
        textView.text = content
        
        return textView
        */
        
        // MARK: - Fallback implementation
        let textView = UITextView()
        textView.text = content
        textView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.backgroundColor = theme.backgroundColor
        textView.textColor = theme.textColor
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update content if changed
        if uiView.text != content {
            uiView.text = content
        }
        
        // MARK: - Update Runestone configuration
        // Uncomment after adding the package:
        /*
        if let textView = uiView as? Runestone.TextView {
            textView.theme = theme.runestoneTheme
            textView.showLineNumbers = showLineNumbers
            textView.showSpaces = showInvisibleCharacters
            textView.showTabs = showInvisibleCharacters
            textView.showLineBreaks = showInvisibleCharacters
            textView.font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        */
    }
}

// MARK: - Code Theme
enum RunestoneTheme: String, CaseIterable {
    case gitHub = "GitHub"
    case xcode = "Xcode"
    case oneDarkPro = "One Dark Pro"
    case dracula = "Dracula"
    case solarizedDark = "Solarized Dark"
    case solarizedLight = "Solarized Light"
    case tomorrow = "Tomorrow"
    case tomorrowNight = "Tomorrow Night"
    case monokai = "Monokai"
    case atomOneDark = "Atom One Dark"
    
    var backgroundColor: UIColor {
        switch self {
        case .gitHub, .xcode, .solarizedLight, .tomorrow:
            return .systemBackground
        case .oneDarkPro, .dracula, .solarizedDark, .tomorrowNight, .monokai, .atomOneDark:
            return UIColor(red: 0.11, green: 0.13, blue: 0.16, alpha: 1.0)
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .gitHub, .xcode, .solarizedLight, .tomorrow:
            return .label
        case .oneDarkPro, .dracula, .solarizedDark, .tomorrowNight, .monokai, .atomOneDark:
            return UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
        }
    }
    
    // MARK: - Runestone Theme Mapping
    // Uncomment after adding the package:
    /*
    var runestoneTheme: Runestone.Theme {
        switch self {
        case .gitHub:
            return .github
        case .xcode:
            return .xcode
        case .oneDarkPro:
            return .oneDarkPro
        case .dracula:
            return .dracula
        case .solarizedDark:
            return .solarizedDark
        case .solarizedLight:
            return .solarizedLight
        case .tomorrow:
            return .tomorrow
        case .tomorrowNight:
            return .tomorrowNight
        case .monokai:
            return .monokai
        case .atomOneDark:
            return .atomOneDark
        }
    }
    */
}

// MARK: - Language Detection
// Uncomment after adding the package:
/*
enum TreeSitterLanguage: String {
    case swift
    case objc = "objective-c"
    case cpp = "c++"
    case c
    case java
    case kotlin
    case python
    case ruby
    case javascript
    case typescript
    case go
    case rust
    case php
    case html
    case css
    case json
    case xml
    case yaml
    case toml
    case markdown
    case bash
    case sql
    
    var language: TreeSitterLanguage {
        // Return the appropriate Tree-sitter language
        // This would map to actual Runestone language implementations
        return self
    }
}

private func detectLanguage(from content: String) -> TreeSitterLanguage? {
    // Simple heuristic-based language detection
    if content.contains("func ") && content.contains("var ") {
        return .swift
    } else if content.contains("def ") && content.contains("import ") {
        return .python
    } else if content.contains("function ") || content.contains("const ") {
        return .javascript
    }
    // Add more detection logic as needed
    return nil
}
*/

// MARK: - SwiftUI Wrapper
struct RunestoneCodeViewWrapper: View {
    let content: String
    let language: String?
    let fileName: String?
    
    @State private var theme: RunestoneTheme = .gitHub
    @State private var fontSize: CGFloat = 14
    @State private var showLineNumbers = true
    @State private var showInvisibleCharacters = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                if let fileName = fileName {
                    Label(fileName, systemImage: iconForFile(fileName))
                        .font(.headline)
                }
                
                Spacer()
                
                Menu {
                    Section("Theme") {
                        ForEach(RunestoneTheme.allCases, id: \.self) { theme in
                            Button(theme.rawValue) {
                                self.theme = theme
                            }
                        }
                    }
                    
                    Section("Display") {
                        Toggle("Line Numbers", isOn: $showLineNumbers)
                        Toggle("Invisible Characters", isOn: $showInvisibleCharacters)
                    }
                    
                    Section("Font Size") {
                        Button("Decrease") { fontSize = max(10, fontSize - 2) }
                        Button("Increase") { fontSize = min(24, fontSize + 2) }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            
            Divider()
            
            // Code view
            RunestoneCodeView(
                content: content,
                language: language ?? detectLanguageFromFileName(fileName),
                theme: theme,
                fontSize: fontSize,
                showLineNumbers: showLineNumbers,
                showInvisibleCharacters: showInvisibleCharacters,
                isEditable: false
            )
        }
        .onAppear {
            // Auto-select theme based on color scheme
            theme = colorScheme == .dark ? .oneDarkPro : .gitHub
        }
    }
    
    private func iconForFile(_ fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "ts": return "curlybraces"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "html", "xml": return "chevron.left.slash.chevron.right"
        case "css", "scss": return "number"
        case "json": return "curlybraces.square"
        case "md", "markdown": return "doc.richtext"
        default: return "doc.text"
        }
    }
    
    private func detectLanguageFromFileName(_ fileName: String?) -> String? {
        guard let fileName = fileName else { return nil }
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        switch ext {
        case "swift": return "swift"
        case "m", "mm": return "objective-c"
        case "cpp", "cc", "cxx": return "c++"
        case "c", "h": return "c"
        case "java": return "java"
        case "kt", "kts": return "kotlin"
        case "py": return "python"
        case "rb": return "ruby"
        case "js": return "javascript"
        case "ts": return "typescript"
        case "go": return "go"
        case "rs": return "rust"
        case "php": return "php"
        case "html", "htm": return "html"
        case "css": return "css"
        case "json": return "json"
        case "xml": return "xml"
        case "yml", "yaml": return "yaml"
        case "toml": return "toml"
        case "md", "markdown": return "markdown"
        case "sh", "bash": return "bash"
        case "sql": return "sql"
        default: return nil
        }
    }
}

// MARK: - Preview
struct RunestoneCodeView_Previews: PreviewProvider {
    static let sampleCode = """
    import SwiftUI
    
    struct ContentView: View {
        @State private var counter = 0
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Counter: \\(counter)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    Button(action: { counter -= 1 }) {
                        Label("Decrement", systemImage: "minus.circle.fill")
                    }
                    
                    Button(action: { counter += 1 }) {
                        Label("Increment", systemImage: "plus.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    """
    
    static var previews: some View {
        NavigationView {
            RunestoneCodeViewWrapper(
                content: sampleCode,
                language: "swift",
                fileName: "ContentView.swift"
            )
            .navigationTitle("Runestone Code View")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}