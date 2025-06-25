# MLGit Visualization Enhancements

## Overview

This document describes the enhanced visualization features added to MLGit for better diff viewing and file content display.

## Features Added

### 1. Enhanced Diff View (`EnhancedDiffView.swift`)
- **Proper Git Patch Parsing**: Correctly parses git patch format with headers, stats, and hunks
- **Syntax Highlighting**: Color-coded additions (green), deletions (red), and context lines
- **Line Numbers**: Optional line number display
- **Font Size Control**: Adjustable font size for better readability
- **Split View Option**: Toggle between unified and split diff views (future enhancement)
- **Share Support**: Export diffs as text

### 2. Enhanced File Detail View (`EnhancedFileDetailView.swift`)
- **Syntax Highlighting**: Uses Highlightr for 185+ languages
- **Theme Support**: Multiple themes (GitHub, Xcode, VS Code Dark, Atom One Dark, Monokai)
- **Language Detection**: Automatic language detection based on file extension
- **Line Numbers**: Toggle line numbers on/off
- **Line Wrapping**: Toggle between wrapped and unwrapped lines
- **Binary File Detection**: Proper handling and display of binary files
- **Font Size Control**: Adjustable font size

### 3. Markdown Rendering (`MarkdownView.swift`)
- **Native Markdown Parsing**: Custom parser for common markdown elements
- **Supported Elements**:
  - Headers (H1-H6)
  - Bold and italic text
  - Code blocks with language hints
  - Inline code
  - Lists (ordered and unordered)
  - Blockquotes
  - Links
  - Tables
  - Horizontal rules
- **Styled Rendering**: Proper typography and spacing

## Installation

### Required Packages

Add these packages to your project via Xcode:

1. **Highlightr** (Already included)
   - Used for syntax highlighting
   - Repository: https://github.com/raspu/Highlightr

2. **swift-markdown-ui** (Recommended for full markdown support)
   - Repository: https://github.com/gonzalezreal/swift-markdown-ui
   - To add: File → Add Package Dependencies → Enter URL

### Adding Packages in Xcode

1. Open MLGit.xcodeproj in Xcode
2. Select the project in the navigator
3. Click on "Package Dependencies" tab
4. Click the "+" button
5. Enter the package URL
6. Select version rules and add to target

## Usage

### Using Enhanced Diff View

Replace existing DiffView usage:

```swift
// Old
DiffView(repositoryPath: path, commitSHA: sha)

// New
EnhancedDiffView(repositoryPath: path, commitSHA: sha)
```

### Using Enhanced File View

Replace existing FileDetailView usage:

```swift
// Old
FileDetailView(repositoryPath: path, filePath: file)

// New
EnhancedFileDetailView(repositoryPath: path, filePath: file)
```

## Testing

Use the TestEnhancementsView to test the new components:

```swift
TestEnhancementsView()
```

## Known Issues and Solutions

### Issue: Diff not showing content
**Solution**: The enhanced diff view now properly parses git patch format. It will show:
- Patch headers (commit, author, date, subject)
- File changes with proper highlighting
- Line-by-line diff with context

### Issue: File content blank
**Solution**: The enhanced file view handles:
- Plain text files with syntax highlighting
- Binary files with proper indication
- Markdown files with formatted rendering

### Issue: HTTP 400 errors
**Potential Causes**:
- Incorrect URL construction
- Invalid commit SHA
- Repository path encoding issues

**Debug Steps**:
1. Enable HTMLDebugLogger to capture responses
2. Check URL construction in URLBuilder
3. Verify commit SHA exists in repository

## Future Enhancements

1. **Full Markdown Support**: Integrate swift-markdown-ui for complete markdown rendering
2. **Split Diff View**: Side-by-side diff comparison
3. **Syntax Highlighting in Diffs**: Highlight code syntax within diff lines
4. **Image Support**: Display images in markdown and as binary files
5. **Search in Files**: Find text within displayed files
6. **Code Folding**: Collapse/expand code sections
7. **Minimap**: Quick navigation for large files

## Troubleshooting

### Highlightr Not Working
- Ensure Highlightr package is properly linked
- Check that theme names are valid
- Verify language detection is working

### Markdown Not Rendering
- Check if content is valid markdown
- For full support, add swift-markdown-ui package
- Current implementation handles basic markdown

### Performance Issues
- Large files may take time to highlight
- Consider implementing virtualized scrolling
- Cache highlighted content for repeated views