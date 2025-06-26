import Foundation
import SwiftUI
import Combine

/// Manages navigation state for directory browsing
@MainActor
class NavigationStateManager: ObservableObject {
    /// Navigation path for each repository
    @Published private var navigationPaths: [String: [NavigationPathItem]] = [:]
    
    /// Current repository being browsed
    @Published var currentRepository: String?
    
    /// Navigation history for back/forward navigation
    @Published private var navigationHistory: [NavigationHistoryItem] = []
    private var historyIndex = -1
    
    /// Shared instance
    static let shared = NavigationStateManager()
    
    private init() {}
    
    // MARK: - Navigation Path Item
    struct NavigationPathItem: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let timestamp: Date
        
        init(name: String, path: String) {
            self.name = name
            self.path = path
            self.timestamp = Date()
        }
    }
    
    // MARK: - Navigation History Item
    struct NavigationHistoryItem: Identifiable {
        let id = UUID()
        let repositoryPath: String
        let directoryPath: String
        let timestamp: Date
    }
    
    // MARK: - Public Methods
    
    /// Get the current navigation path for a repository
    func navigationPath(for repository: String) -> [NavigationPathItem] {
        return navigationPaths[repository] ?? []
    }
    
    /// Get the current directory path as a string
    func currentPath(for repository: String) -> String {
        let path = navigationPath(for: repository)
        return path.map { $0.name }.joined(separator: "/")
    }
    
    /// Navigate to a directory
    func navigateToDirectory(in repository: String, directory: String, path: String) {
        var currentPath = navigationPaths[repository] ?? []
        currentPath.append(NavigationPathItem(name: directory, path: path))
        navigationPaths[repository] = currentPath
        
        // Add to history
        addToHistory(repository: repository, path: self.currentPath(for: repository))
    }
    
    /// Navigate up one level
    func navigateUp(in repository: String) -> String? {
        guard var currentPath = navigationPaths[repository], !currentPath.isEmpty else {
            return nil
        }
        
        currentPath.removeLast()
        navigationPaths[repository] = currentPath
        
        let newPath = self.currentPath(for: repository)
        addToHistory(repository: repository, path: newPath)
        
        return newPath
    }
    
    /// Navigate to a specific path level
    func navigateToPathLevel(in repository: String, level: Int) -> String? {
        guard var currentPath = navigationPaths[repository], level >= 0 && level < currentPath.count else {
            return nil
        }
        
        // Keep only up to the specified level
        currentPath = Array(currentPath.prefix(level + 1))
        navigationPaths[repository] = currentPath
        
        let newPath = self.currentPath(for: repository)
        addToHistory(repository: repository, path: newPath)
        
        return newPath
    }
    
    /// Clear navigation path for a repository
    func clearPath(for repository: String) {
        navigationPaths[repository] = []
        addToHistory(repository: repository, path: "")
    }
    
    /// Navigate back in history
    func navigateBack() -> (repository: String, path: String)? {
        guard historyIndex > 0 else { return nil }
        
        historyIndex -= 1
        let item = navigationHistory[historyIndex]
        
        // Restore the path
        restorePath(for: item.repositoryPath, path: item.directoryPath)
        
        return (item.repositoryPath, item.directoryPath)
    }
    
    /// Navigate forward in history
    func navigateForward() -> (repository: String, path: String)? {
        guard historyIndex < navigationHistory.count - 1 else { return nil }
        
        historyIndex += 1
        let item = navigationHistory[historyIndex]
        
        // Restore the path
        restorePath(for: item.repositoryPath, path: item.directoryPath)
        
        return (item.repositoryPath, item.directoryPath)
    }
    
    /// Check if can navigate back
    var canNavigateBack: Bool {
        return historyIndex > 0
    }
    
    /// Check if can navigate forward
    var canNavigateForward: Bool {
        return historyIndex < navigationHistory.count - 1
    }
    
    // MARK: - Private Methods
    
    private func addToHistory(repository: String, path: String) {
        // Remove any forward history when navigating to a new path
        if historyIndex < navigationHistory.count - 1 {
            navigationHistory.removeLast(navigationHistory.count - 1 - historyIndex)
        }
        
        // Add new history item
        let item = NavigationHistoryItem(
            repositoryPath: repository,
            directoryPath: path,
            timestamp: Date()
        )
        navigationHistory.append(item)
        historyIndex = navigationHistory.count - 1
        
        // Limit history size
        if navigationHistory.count > 50 {
            navigationHistory.removeFirst()
            historyIndex -= 1
        }
    }
    
    private func restorePath(for repository: String, path: String) {
        // Clear current path
        navigationPaths[repository] = []
        
        // Rebuild path from string
        if !path.isEmpty {
            let components = path.split(separator: "/").map(String.init)
            var items: [NavigationPathItem] = []
            
            for component in components {
                items.append(NavigationPathItem(name: component, path: component))
            }
            
            navigationPaths[repository] = items
        }
    }
}

// MARK: - SwiftUI Environment Key
private struct NavigationStateManagerKey: EnvironmentKey {
    static let defaultValue = NavigationStateManager.shared
}

extension EnvironmentValues {
    var navigationStateManager: NavigationStateManager {
        get { self[NavigationStateManagerKey.self] }
        set { self[NavigationStateManagerKey.self] = newValue }
    }
}