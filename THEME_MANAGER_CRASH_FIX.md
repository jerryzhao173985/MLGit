# ThemeManager Environment Object Crash Fix

## Issue
The app was crashing with a fatal error:
```
SwiftUICore/EnvironmentObject.swift:93: Fatal error: No ObservableObject of type ThemeManager found. 
A View.environmentObject(_:) for ThemeManager may be missing as an ancestor of this view.
```

## Root Cause
The crash occurred when navigating to `ThemeTestView` which expects a `ThemeManager` environment object:

```swift
struct ThemeTestView: View {
    @EnvironmentObject var themeManager: ThemeManager  // <-- Expects this
    // ...
    .onAppear {
        selectedTheme = themeManager.currentTheme  // <-- Crash here
    }
}
```

However, `ThemeManager` was not being provided as an environment object in the main app entry point.

## Solution
Added `ThemeManager` as an environment object in `MLGitApp.swift`:

```swift
@main
struct MLGitApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var themeManager = ThemeManager.shared  // Added this
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(networkMonitor)
                .environmentObject(themeManager)  // Added this
                .preferredColorScheme(appState.preferredColorScheme)
        }
    }
}
```

## What This Fixes
- Prevents crash when accessing any view that uses `@EnvironmentObject var themeManager`
- Ensures theme management is available throughout the app
- Allows theme switching and persistence to work properly

## Additional Notes
The crash logs also showed another issue where a file fetch was returning 404 and getting commit data instead of file content:
```
GitService: Plain fetch failed with error: httpError(404)
FileContentParser: No blob table, div, or pre found
```

This appears to be a separate issue where the file path `reference_model_src/ops/ewise_unary.cc` doesn't exist in the repository.

## Build Status
✅ **BUILD SUCCEEDED** - The fix has been successfully compiled.