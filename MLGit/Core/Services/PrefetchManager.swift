import Foundation
import SwiftUI
import Combine

/// Manages background prefetching of commonly accessed paths
@MainActor
class PrefetchManager: ObservableObject {
    private static let _shared = PrefetchManager()
    
    static var shared: PrefetchManager {
        return _shared
    }
    
    /// Access patterns tracking
    private var accessPatterns: [String: AccessPattern] = [:]
    
    /// Currently prefetching paths
    @Published private var prefetchingPaths: Set<String> = []
    
    /// Background task for prefetching
    private var prefetchTask: Task<Void, Never>?
    
    private let gitService = GitService.shared
    private let directoryCache = DirectoryCache.shared
    
    private init() {
        // Load access patterns from UserDefaults
        loadAccessPatterns()
        
        // Start background prefetching
        startBackgroundPrefetching()
    }
    
    // MARK: - Access Pattern Tracking
    
    struct AccessPattern {
        let path: String
        let repository: String
        var accessCount: Int
        var lastAccessed: Date
        var averageStayDuration: TimeInterval
        
        var score: Double {
            // Calculate score based on frequency and recency
            let daysSinceAccess = Date().timeIntervalSince(lastAccessed) / (24 * 60 * 60)
            let recencyScore = max(0, 1.0 - (daysSinceAccess / 30.0)) // Decay over 30 days
            let frequencyScore = min(1.0, Double(accessCount) / 10.0) // Cap at 10 accesses
            return recencyScore * 0.7 + frequencyScore * 0.3
        }
    }
    
    // MARK: - Public Methods
    
    /// Track when a path is accessed
    func trackAccess(repository: String, path: String) {
        let key = "\(repository):\(path)"
        
        if var pattern = accessPatterns[key] {
            pattern.accessCount += 1
            pattern.lastAccessed = Date()
            accessPatterns[key] = pattern
        } else {
            let pattern = AccessPattern(
                path: path,
                repository: repository,
                accessCount: 1,
                lastAccessed: Date(),
                averageStayDuration: 0
            )
            accessPatterns[key] = pattern
        }
        
        // Save patterns periodically
        if accessPatterns.count % 10 == 0 {
            saveAccessPatterns()
        }
        
        // Trigger prefetch for related paths
        Task {
            await prefetchRelatedPaths(repository: repository, currentPath: path)
        }
    }
    
    /// Prefetch commonly accessed repositories
    func prefetchCommonRepositories() async {
        // Get top repositories by access count
        let topPatterns = accessPatterns.values
            .filter { $0.path.isEmpty } // Root paths only
            .sorted { $0.score > $1.score }
            .prefix(5)
        
        for pattern in topPatterns {
            await prefetchPath(repository: pattern.repository, path: "")
        }
    }
    
    /// Check if a path is being prefetched
    func isPrefetching(repository: String, path: String) -> Bool {
        let key = "\(repository):\(path)"
        return prefetchingPaths.contains(key)
    }
    
    // MARK: - Private Methods
    
    private func prefetchPath(repository: String, path: String) async {
        let key = "\(repository):\(path)"
        
        // Check if already cached or prefetching
        if await directoryCache.getCachedDirectory(repository: repository, path: path) != nil {
            return
        }
        
        if prefetchingPaths.contains(key) {
            return
        }
        
        // Mark as prefetching
        prefetchingPaths.insert(key)
        defer { prefetchingPaths.remove(key) }
        
        do {
            // Fetch the directory
            let files = try await gitService.fetchTree(
                repositoryPath: repository,
                path: path,
                sha: nil
            )
            
            // Cache it
            await directoryCache.cacheDirectory(
                repository: repository,
                path: path,
                files: files
            )
            
            print("PrefetchManager: Successfully prefetched \(key)")
        } catch {
            print("PrefetchManager: Failed to prefetch \(key): \(error)")
        }
    }
    
    private func prefetchRelatedPaths(repository: String, currentPath: String) async {
        // Get sibling directories (other directories at the same level)
        let parentPath = getParentPath(currentPath)
        
        if let cachedParent = await directoryCache.getCachedDirectory(
            repository: repository,
            path: parentPath
        ) {
            // Prefetch up to 3 sibling directories
            let siblingDirs = cachedParent
                .filter { $0.isDirectory && $0.name != getCurrentDirectory(currentPath) }
                .prefix(3)
            
            for dir in siblingDirs {
                let siblingPath = parentPath.isEmpty ? dir.name : "\(parentPath)/\(dir.name)"
                await prefetchPath(repository: repository, path: siblingPath)
            }
        }
        
        // Prefetch immediate subdirectories of current path
        if let cachedCurrent = await directoryCache.getCachedDirectory(
            repository: repository,
            path: currentPath
        ) {
            let subdirs = cachedCurrent
                .filter { $0.isDirectory }
                .prefix(3)
            
            for dir in subdirs {
                let subdirPath = currentPath.isEmpty ? dir.name : "\(currentPath)/\(dir.name)"
                await prefetchPath(repository: repository, path: subdirPath)
            }
        }
    }
    
    private func startBackgroundPrefetching() {
        prefetchTask = Task {
            while !Task.isCancelled {
                // Wait for 30 seconds before next prefetch cycle
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                
                // Prefetch top accessed paths
                let topPaths = accessPatterns.values
                    .sorted { $0.score > $1.score }
                    .prefix(10)
                
                for pattern in topPaths {
                    if Task.isCancelled { break }
                    await prefetchPath(repository: pattern.repository, path: pattern.path)
                }
            }
        }
    }
    
    private func getParentPath(_ path: String) -> String {
        guard !path.isEmpty else { return "" }
        let components = path.split(separator: "/").map(String.init)
        if components.count <= 1 { return "" }
        return components.dropLast().joined(separator: "/")
    }
    
    private func getCurrentDirectory(_ path: String) -> String {
        guard !path.isEmpty else { return "" }
        let components = path.split(separator: "/").map(String.init)
        return components.last ?? ""
    }
    
    // MARK: - Persistence
    
    private func loadAccessPatterns() {
        // Simple persistence - store as dictionary
        guard let dict = UserDefaults.standard.dictionary(forKey: "MLGitAccessPatterns") as? [String: [String: Any]] else {
            return
        }
        
        var patterns: [String: AccessPattern] = [:]
        for (key, value) in dict {
            if let path = value["path"] as? String,
               let repository = value["repository"] as? String,
               let accessCount = value["accessCount"] as? Int,
               let lastAccessed = value["lastAccessed"] as? Date {
                patterns[key] = AccessPattern(
                    path: path,
                    repository: repository,
                    accessCount: accessCount,
                    lastAccessed: lastAccessed,
                    averageStayDuration: 0
                )
            }
        }
        
        accessPatterns = patterns
        
        // Clean old patterns (older than 60 days)
        let cutoffDate = Date().addingTimeInterval(-60 * 24 * 60 * 60)
        accessPatterns = accessPatterns.filter { $0.value.lastAccessed > cutoffDate }
    }
    
    private func saveAccessPatterns() {
        var dict: [String: [String: Any]] = [:]
        for (key, pattern) in accessPatterns {
            dict[key] = [
                "path": pattern.path,
                "repository": pattern.repository,
                "accessCount": pattern.accessCount,
                "lastAccessed": pattern.lastAccessed
            ]
        }
        UserDefaults.standard.set(dict, forKey: "MLGitAccessPatterns")
    }
    
    deinit {
        prefetchTask?.cancel()
    }
}

// MARK: - View Extension
extension View {
    /// Track access to a path
    func trackPathAccess(repository: String, path: String) -> some View {
        self.onAppear {
            PrefetchManager.shared.trackAccess(repository: repository, path: path)
        }
    }
}