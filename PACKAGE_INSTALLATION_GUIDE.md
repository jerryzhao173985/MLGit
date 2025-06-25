# Package Installation Guide for MLGit

## Adding Swift Packages to the Xcode Project

To add the new visualization enhancement packages, follow these steps in Xcode:

### Method 1: Using Xcode's Package Manager (Recommended)

1. **Open MLGit.xcodeproj in Xcode**

2. **Add swift-markdown-ui**:
   - Select the project in the navigator
   - Click on the "Package Dependencies" tab
   - Click the "+" button
   - Enter: `https://github.com/gonzalezreal/swift-markdown-ui`
   - Version: "Up to Next Major Version" from 2.3.0
   - Click "Add Package"
   - Select "MarkdownUI" product and add to MLGit target

3. **Add Runestone**:
   - Click the "+" button again
   - Enter: `https://github.com/simonbs/Runestone`
   - Version: "Up to Next Major Version" from 0.3.0
   - Click "Add Package"
   - Select "Runestone" product and add to MLGit target

4. **Add GitDiff** (if available via SPM):
   - Click the "+" button
   - Enter: `https://github.com/guillermomuntaner/GitDiff`
   - Version: "Up to Next Major Version" from 1.0.0
   - Click "Add Package"
   - Select "GitDiff" product and add to MLGit target

### Method 2: Manual Package.resolved Update

If Method 1 doesn't work, you can manually update the Package.resolved file and let Xcode sync.

### Alternative: CocoaPods (for GitDiff)

If GitDiff is not available via Swift Package Manager, you may need to use CocoaPods:

1. Install CocoaPods if not already installed:
   ```bash
   sudo gem install cocoapods
   ```

2. Create a Podfile in the project root:
   ```ruby
   platform :ios, '16.0'
   use_frameworks!

   target 'MLGit' do
     pod 'GitDiff'
   end
   ```

3. Run:
   ```bash
   pod install
   ```

4. Use MLGit.xcworkspace instead of MLGit.xcodeproj

## Package Features

### swift-markdown-ui (MarkdownUI)
- Full GitHub Flavored Markdown support
- Customizable themes and styling
- Tables, task lists, code blocks
- High performance with pre-parsing

### Runestone
- Tree-sitter based syntax highlighting
- 180+ language support
- Line numbers and invisible characters
- Multiple themes (GitHub, Dracula, Solarized, etc.)
- Excellent performance with large files

### GitDiff
- Parse git unified diffs
- Models for diffs, headers, hunks, and lines
- Support for GitLab diff formats

## Troubleshooting

### Package Resolution Issues
1. Clean build folder: Product → Clean Build Folder (⇧⌘K)
2. Reset package caches: File → Packages → Reset Package Caches
3. Delete DerivedData if needed

### Import Errors
Make sure to import the correct module names:
```swift
import MarkdownUI      // for swift-markdown-ui
import Runestone       // for Runestone
import GitDiff         // for GitDiff (if using SPM)
```

### Version Conflicts
If you encounter version conflicts, try:
1. Updating to the latest compatible versions
2. Check the package's GitHub releases for compatibility notes
3. Use exact version requirements if needed