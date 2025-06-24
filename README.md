# MLGit iOS

A native iOS client for browsing MLPlatform Git repositories (git.mlplatform.org).

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

The project uses two local Swift packages that need to be added to Xcode:

1. In Xcode, go to **File → Add Package Dependencies**
2. Click the "Add Local..." button
3. Navigate to `MLGit/Packages/GitHTMLParser` and add it
4. Repeat for `MLGit/Packages/GitDiffUI`

### Project Structure

```
MLGit/
├── App/                # App entry point and main views
├── Core/               # Business logic and services
│   ├── Models/         # Domain models
│   ├── Networking/     # API layer
│   └── Services/       # Git service
├── Features/           # Feature modules
│   ├── Explore/        # Project catalogue
│   ├── Repository/     # Repository details
│   ├── Commits/        # Commit history
│   ├── FileBrowser/    # File viewing
│   ├── Starred/        # Favorites
│   └── Settings/       # App settings
└── Packages/           # Local Swift packages
    ├── GitHTMLParser/  # HTML parsing
    └── GitDiffUI/      # Diff rendering
```

## Features

- Browse MLPlatform repositories
- View repository details, commits, and files
- Star favorite projects
- View commit patches and diffs
- Offline caching support
- Dark mode support

## Development

### Running Tests
```bash
# In Xcode
Cmd+U

# From terminal
xcodebuild test -scheme MLGit -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Code Style
The project uses SwiftLint for code quality. Run before committing:
```bash
swiftlint
```

## License
[Add your license here]