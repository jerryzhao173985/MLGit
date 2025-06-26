import SwiftUI

/// Smart code view that provides syntax highlighting
struct SmartCodeView: View {
    let content: String
    let language: String
    let fontSize: CGFloat
    let theme: String
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    
    var body: some View {
        // Use EnhancedCodeView for sophisticated syntax highlighting
        EnhancedCodeView(
            content: content,
            language: language,
            fontSize: fontSize,
            theme: theme,
            showLineNumbers: showLineNumbers,
            wrapLines: wrapLines,
            searchText: searchText
        )
        .onAppear {
            print("SmartCodeView: Displaying \(language) file with \(content.components(separatedBy: .newlines).count) lines")
        }
    }
}