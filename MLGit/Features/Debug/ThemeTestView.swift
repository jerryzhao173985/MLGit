import SwiftUI

/// Test view for the unified theme system
struct ThemeTestView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTheme: CodeTheme = .gitHub
    @State private var showingAllThemes = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Theme selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme Selection")
                        .font(.headline)
                    
                    Picker("Current Theme", selection: $selectedTheme) {
                        ForEach(CodeTheme.allCases, id: \.id) { theme in
                            Text(theme.name).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTheme) { _, newTheme in
                        themeManager.setTheme(newTheme)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Theme preview
                ThemePreviewCard(theme: selectedTheme)
                
                // Code sample with current theme
                VStack(alignment: .leading, spacing: 12) {
                    Text("Code Preview")
                        .font(.headline)
                    
                    CodeThemePreview(theme: selectedTheme)
                }
                .padding()
                .background(selectedTheme.backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedTheme.borderColor, lineWidth: 1)
                )
                
                // Diff preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Diff Preview")
                        .font(.headline)
                    
                    DiffThemePreview(theme: selectedTheme)
                }
                .padding()
                .background(selectedTheme.backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedTheme.borderColor, lineWidth: 1)
                )
                
                // All themes grid
                if showingAllThemes {
                    AllThemesGrid()
                }
                
                Button(showingAllThemes ? "Hide All Themes" : "Show All Themes") {
                    withAnimation {
                        showingAllThemes.toggle()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .navigationTitle("Theme System")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedTheme = themeManager.currentTheme
        }
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    let theme: CodeTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(theme.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(theme.isDark ? "Dark Theme" : "Light Theme")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(theme.backgroundColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(theme.borderColor, lineWidth: 2)
                    )
            }
            
            // Color palette
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ColorSwatch(label: "Keyword", color: theme.keywordColor)
                ColorSwatch(label: "String", color: theme.stringColor)
                ColorSwatch(label: "Number", color: theme.numberColor)
                ColorSwatch(label: "Function", color: theme.functionColor)
                ColorSwatch(label: "Variable", color: theme.variableColor)
                ColorSwatch(label: "Type", color: theme.typeColor)
                ColorSwatch(label: "Comment", color: theme.commentColor)
                ColorSwatch(label: "Operator", color: theme.operatorColor)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Color Swatch
struct ColorSwatch: View {
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Code Theme Preview
struct CodeThemePreview: View {
    let theme: CodeTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                Text("1  ").foregroundColor(theme.lineNumberColor).font(.system(size: theme.fontSize - 2, design: .monospaced))
                Text("import ").foregroundColor(theme.keywordColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("SwiftUI").foregroundColor(theme.typeColor).font(.system(size: theme.fontSize, design: .monospaced))
            }
            
            HStack(spacing: 0) {
                Text("2  ").foregroundColor(theme.lineNumberColor).font(.system(size: theme.fontSize - 2, design: .monospaced))
                Text("")
            }
            
            HStack(spacing: 0) {
                Text("3  ").foregroundColor(theme.lineNumberColor).font(.system(size: theme.fontSize - 2, design: .monospaced))
                Text("// A sample view").foregroundColor(theme.commentColor).font(.system(size: theme.fontSize, design: .monospaced))
            }
            
            HStack(spacing: 0) {
                Text("4  ").foregroundColor(theme.lineNumberColor).font(.system(size: theme.fontSize - 2, design: .monospaced))
                Text("struct ").foregroundColor(theme.keywordColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("ContentView").foregroundColor(theme.typeColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text(": ").foregroundColor(theme.punctuationColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("View ").foregroundColor(theme.typeColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("{").foregroundColor(theme.punctuationColor).font(.system(size: theme.fontSize, design: .monospaced))
            }
            
            HStack(spacing: 0) {
                Text("5  ").foregroundColor(theme.lineNumberColor).font(.system(size: theme.fontSize - 2, design: .monospaced))
                Text("    @State ").foregroundColor(theme.keywordColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("private var ").foregroundColor(theme.keywordColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("count ").foregroundColor(theme.variableColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("= ").foregroundColor(theme.operatorColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("0").foregroundColor(theme.numberColor).font(.system(size: theme.fontSize, design: .monospaced))
            }
            
            HStack(spacing: 0) {
                Text("6  ").foregroundColor(theme.lineNumberColor).font(.system(size: theme.fontSize - 2, design: .monospaced))
                Text("    ")
            }
            
            HStack(spacing: 0) {
                Text("7  ").foregroundColor(theme.lineNumberColor).font(.system(size: theme.fontSize - 2, design: .monospaced))
                Text("    var ").foregroundColor(theme.keywordColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("body").foregroundColor(theme.variableColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text(": ").foregroundColor(theme.punctuationColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("some ").foregroundColor(theme.keywordColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("View ").foregroundColor(theme.typeColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("{").foregroundColor(theme.punctuationColor).font(.system(size: theme.fontSize, design: .monospaced))
            }
            
            HStack(spacing: 0) {
                Text("8  ").foregroundColor(theme.lineNumberColor).font(.system(size: theme.fontSize - 2, design: .monospaced))
                Text("        Text").foregroundColor(theme.functionColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("(").foregroundColor(theme.punctuationColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text("\"Count: \\\\(count)\"").foregroundColor(theme.stringColor).font(.system(size: theme.fontSize, design: .monospaced))
                Text(")").foregroundColor(theme.punctuationColor).font(.system(size: theme.fontSize, design: .monospaced))
            }
        }
        .padding()
        .background(theme.currentLineColor)
        .cornerRadius(8)
    }
}

// MARK: - Diff Theme Preview
struct DiffThemePreview: View {
    let theme: CodeTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("@@ -5,3 +5,5 @@ struct Example {")
                .foregroundColor(theme.diffHunkColor)
                .font(.system(size: theme.fontSize - 1, design: .monospaced))
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(theme.diffHunkColor.opacity(0.1))
            
            HStack(spacing: 0) {
                Text(" ")
                    .frame(width: 20)
                Text("    let name: String")
                    .foregroundColor(theme.foregroundColor)
            }
            .font(.system(size: theme.fontSize, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            
            HStack(spacing: 0) {
                Text("-")
                    .foregroundColor(theme.deletionForegroundColor)
                    .frame(width: 20)
                Text("    let age: Int")
                    .foregroundColor(theme.foregroundColor)
            }
            .font(.system(size: theme.fontSize, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(theme.deletionBackgroundColor)
            
            HStack(spacing: 0) {
                Text("+")
                    .foregroundColor(theme.additionForegroundColor)
                    .frame(width: 20)
                Text("    let age: Int?")
                    .foregroundColor(theme.foregroundColor)
            }
            .font(.system(size: theme.fontSize, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(theme.additionBackgroundColor)
            
            HStack(spacing: 0) {
                Text("+")
                    .foregroundColor(theme.additionForegroundColor)
                    .frame(width: 20)
                Text("    let email: String")
                    .foregroundColor(theme.foregroundColor)
            }
            .font(.system(size: theme.fontSize, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(theme.additionBackgroundColor)
        }
        .cornerRadius(8)
    }
}

// MARK: - All Themes Grid
struct AllThemesGrid: View {
    let themes = CodeTheme.allCases.filter { $0.id != "automatic" }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Available Themes")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(themes, id: \.id) { theme in
                    ThemeThumbnail(theme: theme)
                }
            }
        }
        .padding(.vertical)
    }
}

struct ThemeThumbnail: View {
    let theme: CodeTheme
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(theme.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                if theme.isDark {
                    Image(systemName: "moon.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Mini code preview
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 2) {
                    Text("func").foregroundColor(theme.keywordColor).font(.system(size: 10, design: .monospaced))
                    Text("hello").foregroundColor(theme.functionColor).font(.system(size: 10, design: .monospaced))
                    Text("()").foregroundColor(theme.punctuationColor).font(.system(size: 10, design: .monospaced))
                }
                HStack(spacing: 2) {
                    Text("let").foregroundColor(theme.keywordColor).font(.system(size: 10, design: .monospaced))
                    Text("x").foregroundColor(theme.variableColor).font(.system(size: 10, design: .monospaced))
                    Text("=").foregroundColor(theme.operatorColor).font(.system(size: 10, design: .monospaced))
                    Text("42").foregroundColor(theme.numberColor).font(.system(size: 10, design: .monospaced))
                }
            }
            .padding(8)
            .background(theme.backgroundColor)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(theme.borderColor, lineWidth: 0.5)
            )
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
        .onTapGesture {
            themeManager.setTheme(theme)
        }
    }
}

// MARK: - Preview
struct ThemeTestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ThemeTestView()
                .environmentObject(ThemeManager.shared)
        }
    }
}