# MLGit - iOS Client for git.mlplatform.org

MLGit is a native iOS client for browsing repositories hosted on git.mlplatform.org, which uses cgit as its Git web interface.

## Features

### Core Features
- 📱 Native iOS app built with SwiftUI
- 🌐 Browse ML platform repositories (ml, tosa sections)
- ⭐ Star repositories locally with update notifications
- 🔍 Search and filter repositories
- 📊 View repository details, commits, branches, and files
- 🌙 Dark mode support

### Enhanced Features Implemented
- 🚀 Comprehensive cgit HTML parsing
  - Repository list with categories and last activity
  - Commit history with author details and pagination
  - File browser with directory navigation
  - Branch and tag browsing (refs)
  - Commit detail view with diff stats
  - Repository summary page parsing
- 💾 Intelligent offline mode
  - Custom caching system (100MB limit)
  - Cached content available offline
  - Visual offline mode indicator
  - Cache management UI
- 🔄 Enhanced UI/UX
  - Pull-to-refresh on all list views
  - Loading skeleton views
  - Comprehensive error states with retry
  - Network connectivity monitoring
  - Tab-based repository navigation
- 🔔 Starred repositories features
  - Local persistence using UserDefaults
  - Background update checking
  - Visual indicators for new commits
  - Last checked timestamp display

## Architecture

### Project Structure
```
MLGit/
├── App/                    # App entry point and configuration
│   ├── MLGitApp.swift     # Main app with NetworkMonitor
│   ├── ContentView.swift  # Tab navigation with offline indicator
│   └── AppState.swift     # Global app state management
├── Core/                   # Core utilities and services
│   ├── Cache/             # Custom caching system
│   ├── Extensions/        # View+ErrorHandling, etc.
│   ├── Models/            # Domain models (Repository, Commit, etc.)
│   ├── Networking/        # Network layer with caching
│   ├── Services/          # GitService business logic
│   ├── Utilities/         # NetworkMonitor, URLBuilder
│   └── Views/             # Reusable views (LoadingStateView, etc.)
├── Features/              # Feature modules
│   ├── Commits/           # Commit list and detail views
│   ├── Explore/           # Repository discovery with search
│   ├── FileBrowser/       # Tree navigation and file viewing
│   ├── Repository/        # Repository detail with tabs
│   ├── Settings/          # App settings and about
│   └── Starred/           # Starred repos with update checking
└── Packages/              # Local Swift packages
    ├── GitDiffUI/         # Diff visualization (future)
    └── GitHTMLParser/     # cgit HTML parsing
        └── Sources/
            ├── BaseParser.swift
            ├── CatalogueParser.swift
            ├── CommitListParser.swift
            ├── TreeParser.swift
            ├── RefsParser.swift
            ├── CommitDetailParser.swift
            ├── DiffParser.swift
            └── SummaryParser.swift
```

### Key Components

#### Enhanced HTML Parsers
All parsers handle cgit's specific HTML structure:
- `CatalogueParser` - Parses repository list with sections
- `CommitListParser` - Handles commit history with pagination
- `TreeParser` - Parses file/directory listings
- `RefsParser` - Extracts branches and tags
- `CommitDetailParser` - Full commit info with Change-Id
- `DiffParser` - Parses diffs and patches
- `SummaryParser` - Repository overview page

#### Services
- `GitService` - Main service coordinating all Git operations
- `NetworkService` - Network layer with URLCache and custom caching
- `CacheManager` - Hybrid memory/disk cache with expiration
- `NetworkMonitor` - Real-time connectivity monitoring
- `StarredViewModel` - Manages starred repos with update checking

#### UI Components
- `LoadingStateView` - Consistent loading UI
- `LoadingSkeletonView` - Skeleton loading animation
- `EmptyStateView` - Empty states with actions
- `ErrorStateView` - Error display with retry
- `NoConnectionView` - Offline state
- `OfflineModeView` - Offline indicator with info sheet
- `TabButton` - Custom tab navigation

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0+ deployment target
- macOS 13.0+ for development

### Building the Project

1. Open `MLGit.xcodeproj` in Xcode
2. Wait for Swift Package Manager to resolve dependencies
3. Select your target device or simulator
4. Press `Cmd+R` to build and run

### Adding Local Packages

The project uses two local Swift packages:

1. In Xcode, go to **File → Add Package Dependencies**
2. Click the "Add Local..." button
3. Navigate to `MLGit/Packages/GitHTMLParser` and add it
4. Repeat for `MLGit/Packages/GitDiffUI`

### Known Issues

If you see "Unable to find module dependency: 'GitHTMLParser'":
1. Clean build folder: `Cmd+Shift+K`
2. Reset package caches: File → Packages → Reset Package Caches
3. Close and reopen Xcode

## Configuration

The app is configured to work with git.mlplatform.org by default:
- Base URL: `https://git.mlplatform.org` (in URLBuilder.swift)
- User Agent: `MLGit-iOS/1.0`
- Cache limits: 100MB disk, 10MB memory
- Cache expiration: 1 hour

## Development

### Running Tests
```bash
# In Xcode
Cmd+U

# From terminal
xcodebuild test -scheme MLGit -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Code Style
The project includes SwiftLint configuration (`.swiftlint.yml`):
```bash
# Install SwiftLint
brew install swiftlint

# Run linting
swiftlint
```

### Debugging
- Network requests are logged to console
- Parser errors include detailed context
- Cache operations can be monitored in CacheManager

## Future Enhancements

The following features are partially implemented or planned:
- [ ] Syntax highlighting for file content (Highlightr integrated)
- [ ] Full diff viewer with side-by-side view
- [ ] Advanced search with filters
- [ ] Background fetch for starred repos
- [ ] Push notifications for updates
- [ ] Widget support for starred repos
- [ ] Deep linking support
- [ ] Commit graph visualization
- [ ] Clone URL management

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Ensure SwiftLint passes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built for the ML Platform community
- Uses SwiftSoup for HTML parsing
- Inspired by GitHub mobile app UX patterns