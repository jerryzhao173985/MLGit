import SwiftUI
import Foundation
import Combine

/// Unified theme system for all code viewers in MLGit
///
/// This provides consistent theming across:
/// - Code viewers (syntax highlighting)
/// - Diff viewers
/// - Markdown renderers
/// - General UI components
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("selectedTheme") private var selectedThemeId: String = CodeTheme.automatic.id
    @AppStorage("preferredLightTheme") private var preferredLightThemeId: String = CodeTheme.gitHub.id
    @AppStorage("preferredDarkTheme") private var preferredDarkThemeId: String = CodeTheme.oneDarkPro.id
    
    @Published var currentTheme: CodeTheme = .gitHub
    
    private init() {
        updateCurrentTheme()
    }
    
    func setTheme(_ theme: CodeTheme) {
        selectedThemeId = theme.id
        updateCurrentTheme()
    }
    
    func setPreferredLightTheme(_ theme: CodeTheme) {
        preferredLightThemeId = theme.id
        updateCurrentTheme()
    }
    
    func setPreferredDarkTheme(_ theme: CodeTheme) {
        preferredDarkThemeId = theme.id
        updateCurrentTheme()
    }
    
    private func updateCurrentTheme() {
        if selectedThemeId == CodeTheme.automatic.id {
            // Use system appearance
            let colorScheme = UITraitCollection.current.userInterfaceStyle
            currentTheme = colorScheme == .dark ? 
                (CodeTheme.allCases.first { $0.id == preferredDarkThemeId } ?? .oneDarkPro) :
                (CodeTheme.allCases.first { $0.id == preferredLightThemeId } ?? .gitHub)
        } else {
            currentTheme = CodeTheme.allCases.first { $0.id == selectedThemeId } ?? .gitHub
        }
    }
}

/// Code theme definition with comprehensive styling
struct CodeTheme: Identifiable, Equatable, Hashable, CaseIterable {
    let id: String
    let name: String
    let isDark: Bool
    
    // Colors
    let backgroundColor: Color
    let foregroundColor: Color
    let selectionColor: Color
    let currentLineColor: Color
    let lineNumberColor: Color
    let commentColor: Color
    let keywordColor: Color
    let stringColor: Color
    let numberColor: Color
    let functionColor: Color
    let variableColor: Color
    let typeColor: Color
    let operatorColor: Color
    let punctuationColor: Color
    
    // Diff colors
    let additionBackgroundColor: Color
    let deletionBackgroundColor: Color
    let additionForegroundColor: Color
    let deletionForegroundColor: Color
    let diffHeaderColor: Color
    let diffHunkColor: Color
    
    // UI colors
    let borderColor: Color
    let shadowColor: Color
    
    // Font settings
    let fontSize: CGFloat
    let lineHeight: CGFloat
    
    static let automatic = CodeTheme(
        id: "automatic",
        name: "Automatic",
        isDark: false,
        backgroundColor: .clear,
        foregroundColor: .primary,
        selectionColor: .accentColor.opacity(0.2),
        currentLineColor: .secondary.opacity(0.05),
        lineNumberColor: .secondary.opacity(0.6),
        commentColor: .secondary,
        keywordColor: .purple,
        stringColor: .red,
        numberColor: .blue,
        functionColor: .orange,
        variableColor: .primary,
        typeColor: .teal,
        operatorColor: .pink,
        punctuationColor: .secondary,
        additionBackgroundColor: .green.opacity(0.1),
        deletionBackgroundColor: .red.opacity(0.1),
        additionForegroundColor: .green,
        deletionForegroundColor: .red,
        diffHeaderColor: .blue,
        diffHunkColor: .purple,
        borderColor: Color(.separator),
        shadowColor: .black.opacity(0.1),
        fontSize: 14,
        lineHeight: 1.4
    )
    
    static let gitHub = CodeTheme(
        id: "github",
        name: "GitHub",
        isDark: false,
        backgroundColor: Color(hex: "#ffffff"),
        foregroundColor: Color(hex: "#24292e"),
        selectionColor: Color(hex: "#0366d6").opacity(0.15),
        currentLineColor: Color(hex: "#f6f8fa"),
        lineNumberColor: Color(hex: "#959da5"),
        commentColor: Color(hex: "#6a737d"),
        keywordColor: Color(hex: "#d73a49"),
        stringColor: Color(hex: "#032f62"),
        numberColor: Color(hex: "#005cc5"),
        functionColor: Color(hex: "#6f42c1"),
        variableColor: Color(hex: "#24292e"),
        typeColor: Color(hex: "#e36209"),
        operatorColor: Color(hex: "#d73a49"),
        punctuationColor: Color(hex: "#24292e"),
        additionBackgroundColor: Color(hex: "#e6ffed"),
        deletionBackgroundColor: Color(hex: "#ffeef0"),
        additionForegroundColor: Color(hex: "#22863a"),
        deletionForegroundColor: Color(hex: "#cb2431"),
        diffHeaderColor: Color(hex: "#0366d6"),
        diffHunkColor: Color(hex: "#6f42c1"),
        borderColor: Color(hex: "#e1e4e8"),
        shadowColor: Color(hex: "#000000").opacity(0.08),
        fontSize: 14,
        lineHeight: 1.45
    )
    
    static let xcode = CodeTheme(
        id: "xcode",
        name: "Xcode",
        isDark: false,
        backgroundColor: Color(hex: "#ffffff"),
        foregroundColor: Color(hex: "#000000"),
        selectionColor: Color(hex: "#b3d7ff"),
        currentLineColor: Color(hex: "#ecf5ff"),
        lineNumberColor: Color(hex: "#7f8c98"),
        commentColor: Color(hex: "#5d6c79"),
        keywordColor: Color(hex: "#9b2393"),
        stringColor: Color(hex: "#d12f1b"),
        numberColor: Color(hex: "#272ad8"),
        functionColor: Color(hex: "#294c50"),
        variableColor: Color(hex: "#000000"),
        typeColor: Color(hex: "#703daa"),
        operatorColor: Color(hex: "#000000"),
        punctuationColor: Color(hex: "#000000"),
        additionBackgroundColor: Color(hex: "#e6ffed"),
        deletionBackgroundColor: Color(hex: "#ffebe9"),
        additionForegroundColor: Color(hex: "#22863a"),
        deletionForegroundColor: Color(hex: "#cb2431"),
        diffHeaderColor: Color(hex: "#0366d6"),
        diffHunkColor: Color(hex: "#6f42c1"),
        borderColor: Color(hex: "#d1d1d1"),
        shadowColor: Color(hex: "#000000").opacity(0.1),
        fontSize: 13,
        lineHeight: 1.4
    )
    
    static let oneDarkPro = CodeTheme(
        id: "one-dark-pro",
        name: "One Dark Pro",
        isDark: true,
        backgroundColor: Color(hex: "#282c34"),
        foregroundColor: Color(hex: "#abb2bf"),
        selectionColor: Color(hex: "#3e4451"),
        currentLineColor: Color(hex: "#2c323c"),
        lineNumberColor: Color(hex: "#5c6370"),
        commentColor: Color(hex: "#5c6370"),
        keywordColor: Color(hex: "#c678dd"),
        stringColor: Color(hex: "#98c379"),
        numberColor: Color(hex: "#d19a66"),
        functionColor: Color(hex: "#61afef"),
        variableColor: Color(hex: "#e06c75"),
        typeColor: Color(hex: "#e5c07b"),
        operatorColor: Color(hex: "#56b6c2"),
        punctuationColor: Color(hex: "#abb2bf"),
        additionBackgroundColor: Color(hex: "#1e3a1e"),
        deletionBackgroundColor: Color(hex: "#3a1e1e"),
        additionForegroundColor: Color(hex: "#98c379"),
        deletionForegroundColor: Color(hex: "#e06c75"),
        diffHeaderColor: Color(hex: "#61afef"),
        diffHunkColor: Color(hex: "#c678dd"),
        borderColor: Color(hex: "#3e4451"),
        shadowColor: Color(hex: "#000000").opacity(0.3),
        fontSize: 14,
        lineHeight: 1.5
    )
    
    static let dracula = CodeTheme(
        id: "dracula",
        name: "Dracula",
        isDark: true,
        backgroundColor: Color(hex: "#282a36"),
        foregroundColor: Color(hex: "#f8f8f2"),
        selectionColor: Color(hex: "#44475a"),
        currentLineColor: Color(hex: "#373844"),
        lineNumberColor: Color(hex: "#6272a4"),
        commentColor: Color(hex: "#6272a4"),
        keywordColor: Color(hex: "#ff79c6"),
        stringColor: Color(hex: "#f1fa8c"),
        numberColor: Color(hex: "#bd93f9"),
        functionColor: Color(hex: "#50fa7b"),
        variableColor: Color(hex: "#f8f8f2"),
        typeColor: Color(hex: "#8be9fd"),
        operatorColor: Color(hex: "#ff79c6"),
        punctuationColor: Color(hex: "#f8f8f2"),
        additionBackgroundColor: Color(hex: "#1a3a1a"),
        deletionBackgroundColor: Color(hex: "#3a1a1a"),
        additionForegroundColor: Color(hex: "#50fa7b"),
        deletionForegroundColor: Color(hex: "#ff5555"),
        diffHeaderColor: Color(hex: "#8be9fd"),
        diffHunkColor: Color(hex: "#bd93f9"),
        borderColor: Color(hex: "#44475a"),
        shadowColor: Color(hex: "#000000").opacity(0.4),
        fontSize: 14,
        lineHeight: 1.5
    )
    
    static let solarizedLight = CodeTheme(
        id: "solarized-light",
        name: "Solarized Light",
        isDark: false,
        backgroundColor: Color(hex: "#fdf6e3"),
        foregroundColor: Color(hex: "#657b83"),
        selectionColor: Color(hex: "#eee8d5"),
        currentLineColor: Color(hex: "#eee8d5"),
        lineNumberColor: Color(hex: "#93a1a1"),
        commentColor: Color(hex: "#93a1a1"),
        keywordColor: Color(hex: "#859900"),
        stringColor: Color(hex: "#2aa198"),
        numberColor: Color(hex: "#d33682"),
        functionColor: Color(hex: "#b58900"),
        variableColor: Color(hex: "#657b83"),
        typeColor: Color(hex: "#cb4b16"),
        operatorColor: Color(hex: "#859900"),
        punctuationColor: Color(hex: "#657b83"),
        additionBackgroundColor: Color(hex: "#e6ffed"),
        deletionBackgroundColor: Color(hex: "#ffeef0"),
        additionForegroundColor: Color(hex: "#22863a"),
        deletionForegroundColor: Color(hex: "#cb2431"),
        diffHeaderColor: Color(hex: "#268bd2"),
        diffHunkColor: Color(hex: "#b58900"),
        borderColor: Color(hex: "#eee8d5"),
        shadowColor: Color(hex: "#000000").opacity(0.05),
        fontSize: 14,
        lineHeight: 1.4
    )
    
    static let solarizedDark = CodeTheme(
        id: "solarized-dark",
        name: "Solarized Dark",
        isDark: true,
        backgroundColor: Color(hex: "#002b36"),
        foregroundColor: Color(hex: "#839496"),
        selectionColor: Color(hex: "#073642"),
        currentLineColor: Color(hex: "#073642"),
        lineNumberColor: Color(hex: "#586e75"),
        commentColor: Color(hex: "#586e75"),
        keywordColor: Color(hex: "#859900"),
        stringColor: Color(hex: "#2aa198"),
        numberColor: Color(hex: "#d33682"),
        functionColor: Color(hex: "#b58900"),
        variableColor: Color(hex: "#839496"),
        typeColor: Color(hex: "#cb4b16"),
        operatorColor: Color(hex: "#859900"),
        punctuationColor: Color(hex: "#839496"),
        additionBackgroundColor: Color(hex: "#1a3a1a"),
        deletionBackgroundColor: Color(hex: "#3a1a1a"),
        additionForegroundColor: Color(hex: "#859900"),
        deletionForegroundColor: Color(hex: "#dc322f"),
        diffHeaderColor: Color(hex: "#268bd2"),
        diffHunkColor: Color(hex: "#b58900"),
        borderColor: Color(hex: "#073642"),
        shadowColor: Color(hex: "#000000").opacity(0.5),
        fontSize: 14,
        lineHeight: 1.4
    )
    
    static let monokai = CodeTheme(
        id: "monokai",
        name: "Monokai",
        isDark: true,
        backgroundColor: Color(hex: "#272822"),
        foregroundColor: Color(hex: "#f8f8f2"),
        selectionColor: Color(hex: "#49483e"),
        currentLineColor: Color(hex: "#3e3d32"),
        lineNumberColor: Color(hex: "#75715e"),
        commentColor: Color(hex: "#75715e"),
        keywordColor: Color(hex: "#f92672"),
        stringColor: Color(hex: "#e6db74"),
        numberColor: Color(hex: "#ae81ff"),
        functionColor: Color(hex: "#a6e22e"),
        variableColor: Color(hex: "#f8f8f2"),
        typeColor: Color(hex: "#66d9ef"),
        operatorColor: Color(hex: "#f92672"),
        punctuationColor: Color(hex: "#f8f8f2"),
        additionBackgroundColor: Color(hex: "#1e3a1e"),
        deletionBackgroundColor: Color(hex: "#3a1e1e"),
        additionForegroundColor: Color(hex: "#a6e22e"),
        deletionForegroundColor: Color(hex: "#f92672"),
        diffHeaderColor: Color(hex: "#66d9ef"),
        diffHunkColor: Color(hex: "#ae81ff"),
        borderColor: Color(hex: "#49483e"),
        shadowColor: Color(hex: "#000000").opacity(0.4),
        fontSize: 14,
        lineHeight: 1.5
    )
    
    static var allCases: [CodeTheme] {
        [.automatic, .gitHub, .xcode, .oneDarkPro, .dracula, .solarizedLight, .solarizedDark, .monokai]
    }
    
    static var lightThemes: [CodeTheme] {
        allCases.filter { !$0.isDark && $0.id != "automatic" }
    }
    
    static var darkThemes: [CodeTheme] {
        allCases.filter { $0.isDark }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Environment Key
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = CodeTheme.gitHub
}

extension EnvironmentValues {
    var codeTheme: CodeTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}