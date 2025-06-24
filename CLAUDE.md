# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MLGit is a SwiftUI iOS app for browsing Git repositories on MLPlatform. It uses MVVM architecture and scrapes HTML from git.mlplatform.org rather than using a REST API.

## Essential Commands

### Build and Run
```bash
# Open project in Xcode
open MLGit.xcodeproj

# Build from command line
xcodebuild -resolvePackageDependencies
xcodebuild -scheme MLGit -configuration Debug -sdk iphonesimulator

# Run tests
xcodebuild test -scheme MLGit -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Code Quality
```bash
# Run SwiftLint (must have SwiftLint installed)
swiftlint

# Auto-fix SwiftLint issues
swiftlint --fix
```

## Architecture

### Directory Structure
- **App/**: Application entry point and main container (MLGitApp, ContentView)
- **Core/**: Business logic layer
  - Models: Repository, Commit, FileNode, Project, Note
  - Services: GitService (singleton for all git operations)
  - Networking: NetworkService and URLBuilder for API calls
  - Parsing: HTML parsing logic
- **Features/**: UI modules following View + ViewModel pattern
  - Explore, Repository, Commits, FileBrowser, Starred, Settings
- **Packages/**: Local Swift packages
  - GitHTMLParser: Parses git web interface HTML
  - GitDiffUI: Renders diffs with syntax highlighting

### Key Architectural Patterns
1. **MVVM with SwiftUI**: ViewModels use `@Published` properties, Views observe with `@StateObject`/@ObservedObject`
2. **Singleton Services**: GitService manages all git operations
3. **HTML Scraping**: App parses HTML from git.mlplatform.org using SwiftSoup
4. **Global State**: AppState in MLGitApp manages app-wide state and error display
5. **Async/Await**: All network operations use modern Swift concurrency

### Adding New Features
1. Create feature folder in `/Features/`
2. Add View and ViewModel files following existing patterns
3. ViewModels should inherit from `ObservableObject` and use `@Published`
4. Use GitService for any git-related operations
5. Error handling: Throw errors up to AppState for display

### Testing
- Test files go in `MLGitTests/`
- Local packages have their own test targets
- Run tests with Cmd+U in Xcode or via xcodebuild

### SwiftLint Rules
Key enabled rules: force_unwrapping, implicitly_unwrapped_optional, empty_count, closure_spacing
Disabled: line_length, trailing_whitespace
Identifier naming: 1-60 chars, Type names: 3-50 chars

### Network Layer
- All requests go through NetworkService
- URLBuilder provides type-safe endpoint construction
- Responses are HTML that must be parsed
- Base URL: https://git.mlplatform.org

### Dependencies
- SwiftSoup 2.8.8 (HTML parsing)
- Highlightr 2.3.0 (syntax highlighting)
- Managed via Swift Package Manager in Xcode

### Development Requirements
- iOS 16.0+ deployment target
- Xcode 15.0+
- Swift 5.7+

### Common Issues
If Xcode shows "Unable to find module dependency: 'GitHTMLParser'" errors:
1. Close Xcode completely
2. Run: `xcodebuild -resolvePackageDependencies`
3. Open the project again in Xcode
4. Clean build folder (Cmd+Shift+K)
5. Build again

### Recent Updates
- Fixed UI freezing issues with proper alert binding using onReceive instead of onChange
- Added network connectivity monitoring with NetworkMonitor class
- Updated CatalogueParser to handle git.mlplatform.org HTML structure (both toplevel-repo and sublevel-repo)
- Fixed BaseParser parseDocument method signature issues
- Improved error handling with detailed logging and specific error messages
- Added proper loading and empty states with better UI feedback
- Fixed Settings view links to point to correct URLs
- Fixed repeated network requests by adding loading state checks
- Updated date parsing to handle formats like "45 min." and "3 years"