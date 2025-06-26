import SwiftUI
import MarkdownUI
import Highlightr

struct OptimizedMarkdownView: View {
    let content: String
    let fontSize: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            markdownView
                .padding()
        }
    }
    
    private var markdownView: some View {
        Markdown(content)
            .markdownTheme(.gitHub)
            .markdownTextStyle {
                FontSize(fontSize)
            }
    }
}