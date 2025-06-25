# Enhanced Components Integration Guide

This guide shows how to integrate and use the new enhanced visualization components in MLGit.

## 1. Package Installation

First, add the required packages to your project:

### In Xcode:
1. Select the project → Package Dependencies → "+"
2. Add these packages:
   - `https://github.com/gonzalezreal/swift-markdown-ui` (v2.3.0+)
   - `https://github.com/simonbs/Runestone` (v0.3.0+)
   - `https://github.com/guillermomuntaner/GitDiff` (v1.0.0+)

## 2. Component Integration

### Enhanced Markdown Rendering

Replace the existing MarkdownView with EnhancedMarkdownView:

```swift
// Before
MarkdownView(content: markdownContent, fontSize: 16)

// After (once packages are added)
EnhancedMarkdownView(content: markdownContent)
```

Features:
- Full GitHub Flavored Markdown support
- Tables, task lists, blockquotes
- Syntax highlighted code blocks
- Custom themes

### Advanced Code Viewing with Runestone

Replace EnhancedFileDetailView's code rendering with RunestoneCodeView:

```swift
// In EnhancedFileDetailView.swift
if isMarkdownFile {
    EnhancedMarkdownView(content: content)
} else {
    RunestoneCodeViewWrapper(
        content: content,
        language: detectLanguage(from: filePath),
        fileName: fileName
    )
}
```

Features:
- Tree-sitter based syntax highlighting (fastest)
- 180+ language support
- Line numbers, invisible characters
- Multiple themes (GitHub, Dracula, One Dark Pro, etc.)

### Advanced Diff Viewing

Replace DiffView/EnhancedDiffView with AdvancedDiffView:

```swift
// In CommitDetailView.swift
.sheet(isPresented: $showingPatch) {
    AdvancedDiffView(
        repositoryPath: repositoryPath,
        commitSHA: commitSHA
    )
}
```

Features:
- Split view (side-by-side)
- Unified view with better formatting
- Collapsible hunks
- File tree navigation
- Syntax highlighting within diffs

## 3. Theme System Integration

### Set Up Theme Manager

In MLGitApp.swift:

```swift
@main
struct MLGitApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environment(\.codeTheme, themeManager.currentTheme)
        }
    }
}
```

### Use Themes in Views

```swift
struct SomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.codeTheme) var theme
    
    var body: some View {
        Text("Code")
            .foregroundColor(theme.keywordColor)
            .background(theme.backgroundColor)
    }
}
```

### Theme Settings View

Add to SettingsView:

```swift
Section("Appearance") {
    Picker("Theme", selection: $selectedTheme) {
        ForEach(CodeTheme.allCases) { theme in
            Text(theme.name).tag(theme)
        }
    }
    .onChange(of: selectedTheme) { newTheme in
        themeManager.setTheme(newTheme)
    }
    
    if selectedTheme == .automatic {
        Picker("Light Theme", selection: $lightTheme) {
            ForEach(CodeTheme.lightThemes) { theme in
                Text(theme.name).tag(theme)
            }
        }
        
        Picker("Dark Theme", selection: $darkTheme) {
            ForEach(CodeTheme.darkThemes) { theme in
                Text(theme.name).tag(theme)
            }
        }
    }
}
```

## 4. Performance Optimizations

### For Large Files

```swift
// Use lazy loading in RunestoneCodeView
if content.count > 50000 {
    ProgressView("Loading large file...")
        .task {
            // Load and highlight in background
        }
} else {
    RunestoneCodeView(content: content, ...)
}
```

### For Complex Markdown

```swift
// Pre-parse markdown for better performance
let parsedContent = MarkdownContent(content)
EnhancedMarkdownView(parsedContent: parsedContent)
```

### For Large Diffs

```swift
// Auto-collapse hunks for files with many changes
if file.hunks.count > 10 {
    // Only expand first 3 hunks by default
}
```

## 5. Migration Path

### Phase 1: Add Packages
1. Add packages via Xcode
2. Build to verify no conflicts

### Phase 2: Update Views Gradually
1. Start with TestEnhancementsView to verify
2. Update MarkdownView uses
3. Update code file viewing
4. Update diff viewing

### Phase 3: Full Integration
1. Remove old implementations
2. Update all navigation links
3. Add theme settings

## 6. Troubleshooting

### Package Not Found
- Clean build folder (⇧⌘K)
- Reset package caches
- Check network connection

### Import Errors
```swift
import MarkdownUI      // NOT swift-markdown-ui
import Runestone       // NOT RunestoneTextEditor
import GitDiff         // Check if using SPM or CocoaPods
```

### Performance Issues
- Enable release optimizations for Runestone
- Use pre-parsing for large markdown
- Implement virtualization for very large diffs

## 7. Testing

### Test with Large Files
```swift
// In TestEnhancementsView
NavigationLink("Test Large File") {
    RunestoneCodeViewWrapper(
        content: largeFileContent, // 10k+ lines
        language: "swift"
    )
}
```

### Test Complex Markdown
```swift
NavigationLink("Test Complex Markdown") {
    EnhancedMarkdownView(
        content: complexMarkdownWithTables
    )
}
```

### Test Large Diffs
```swift
NavigationLink("Test Large Diff") {
    AdvancedDiffView(
        repositoryPath: "large/repo.git",
        commitSHA: "largeCommitSHA"
    )
}
```

## 8. Best Practices

1. **Always check package availability** before using enhanced features
2. **Provide fallbacks** for when packages aren't loaded
3. **Use appropriate themes** based on content type
4. **Monitor performance** especially with large files
5. **Cache parsed content** when possible
6. **Respect user preferences** for themes and display options

## Example: Complete Integration

```swift
struct ContentFileView: View {
    let content: String
    let fileName: String
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            if fileName.hasSuffix(".md") {
                #if canImport(MarkdownUI)
                EnhancedMarkdownView(content: content)
                #else
                MarkdownView(content: content, fontSize: 16)
                #endif
            } else {
                #if canImport(Runestone)
                RunestoneCodeViewWrapper(
                    content: content,
                    language: detectLanguage(from: fileName),
                    fileName: fileName
                )
                #else
                EnhancedFileDetailView(
                    repositoryPath: "",
                    filePath: fileName
                )
                #endif
            }
        }
        .navigationTitle(fileName)
    }
}
```

This approach ensures graceful degradation while leveraging enhanced features when available.