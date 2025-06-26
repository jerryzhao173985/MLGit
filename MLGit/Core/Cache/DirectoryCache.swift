import Foundation
import Combine

/// Specialized cache for directory structures with hierarchical caching
@MainActor
class DirectoryCache: ObservableObject {
    private static let _shared = DirectoryCache()
    
    static var shared: DirectoryCache {
        return _shared
    }
    
    /// In-memory cache for directory structures
    private var memoryCache = NSCache<NSString, DirectoryCacheEntry>()
    
    /// Persistent cache using CacheManager
    private let cacheManager = CacheManager.shared
    
    /// Cache for entire repository trees (for prefetching)
    private var repositoryTreeCache: [String: RepositoryTree] = [:]
    
    /// Loading state for directories
    @Published var loadingPaths: Set<String> = []
    
    private init() {
        // Configure memory cache
        memoryCache.countLimit = 500 // Max 500 directories in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    // MARK: - Cache Entry Types
    
    class DirectoryCacheEntry {
        let files: [FileNode]
        let timestamp: Date
        let path: String
        let repository: String
        
        init(files: [FileNode], path: String, repository: String) {
            self.files = files
            self.timestamp = Date()
            self.path = path
            self.repository = repository
        }
        
        var isExpired: Bool {
            // Directory cache expires after 24 hours
            return Date().timeIntervalSince(timestamp) > 24 * 60 * 60
        }
    }
    
    struct RepositoryTree {
        let repository: String
        let directories: [String: [FileNode]]
        let timestamp: Date
        
        var isExpired: Bool {
            // Repository tree cache expires after 12 hours
            return Date().timeIntervalSince(timestamp) > 12 * 60 * 60
        }
    }
    
    // MARK: - Public Methods
    
    /// Get cached directory contents
    func getCachedDirectory(repository: String, path: String) async -> [FileNode]? {
        let cacheKey = "\(repository):\(path)" as NSString
        
        // Check memory cache first
        if let entry = memoryCache.object(forKey: cacheKey) {
            if !entry.isExpired {
                print("DirectoryCache: Memory cache hit for \(path)")
                return entry.files
            } else {
                memoryCache.removeObject(forKey: cacheKey)
            }
        }
        
        // Check persistent cache
        let persistentKey = "dir_\(repository)_\(path)".replacingOccurrences(of: "/", with: "_")
        if let cachedFiles: [FileNode] = await cacheManager.getCachedData([FileNode].self, for: persistentKey) {
            print("DirectoryCache: Persistent cache hit for \(path)")
            
            // Load into memory cache
            let entry = DirectoryCacheEntry(files: cachedFiles, path: path, repository: repository)
            memoryCache.setObject(entry, forKey: cacheKey, cost: estimateMemorySize(cachedFiles))
            
            return cachedFiles
        }
        
        return nil
    }
    
    /// Cache directory contents
    func cacheDirectory(repository: String, path: String, files: [FileNode]) async {
        let cacheKey = "\(repository):\(path)" as NSString
        
        // Sort files for consistent display
        let sortedFiles = files.sorted { file1, file2 in
            if file1.isDirectory != file2.isDirectory {
                return file1.isDirectory
            }
            return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
        }
        
        // Memory cache
        let entry = DirectoryCacheEntry(files: sortedFiles, path: path, repository: repository)
        memoryCache.setObject(entry, forKey: cacheKey, cost: estimateMemorySize(sortedFiles))
        
        // Persistent cache
        let persistentKey = "dir_\(repository)_\(path)".replacingOccurrences(of: "/", with: "_")
        await cacheManager.cacheData(sortedFiles, for: persistentKey, policy: .custom(24 * 60 * 60))
        
        // Update repository tree cache if we have it
        if let tree = repositoryTreeCache[repository] {
            var directories = tree.directories
            directories[path] = sortedFiles
            repositoryTreeCache[repository] = RepositoryTree(
                repository: repository,
                directories: directories,
                timestamp: tree.timestamp
            )
        }
    }
    
    /// Prefetch subdirectories for a given path
    func prefetchSubdirectories(repository: String, path: String, files: [FileNode], gitService: GitService) async {
        // Get subdirectories
        let subdirectories = files.filter { $0.isDirectory }
        
        // Prefetch up to 5 subdirectories
        let prefetchLimit = min(5, subdirectories.count)
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<prefetchLimit {
                let subdir = subdirectories[i]
                let subdirPath = path.isEmpty ? subdir.name : "\(path)/\(subdir.name)"
                
                group.addTask { [weak self] in
                    // Check if already cached
                    if await self?.getCachedDirectory(repository: repository, path: subdirPath) != nil {
                        return
                    }
                    
                    // Fetch and cache
                    do {
                        let subFiles = try await gitService.fetchTree(
                            repositoryPath: repository,
                            path: subdirPath,
                            sha: nil
                        )
                        await self?.cacheDirectory(repository: repository, path: subdirPath, files: subFiles)
                        print("DirectoryCache: Prefetched \(subdirPath)")
                    } catch {
                        print("DirectoryCache: Failed to prefetch \(subdirPath): \(error)")
                    }
                }
            }
        }
    }
    
    /// Load entire repository tree (for initial load optimization)
    func loadRepositoryTree(repository: String) async -> RepositoryTree? {
        // Check if we have a cached tree
        if let tree = repositoryTreeCache[repository], !tree.isExpired {
            return tree
        }
        
        // For now, skip persistent cache for RepositoryTree since it would require custom encoding
        // This is a temporary simplification
        
        return nil
    }
    
    /// Save repository tree
    func saveRepositoryTree(repository: String, directories: [String: [FileNode]]) async {
        let tree = RepositoryTree(
            repository: repository,
            directories: directories,
            timestamp: Date()
        )
        
        repositoryTreeCache[repository] = tree
        
        // For now, skip persistent cache for RepositoryTree since it would require custom encoding
        // This is a temporary simplification
    }
    
    /// Clear cache for a repository
    func clearCache(for repository: String) {
        // Clear memory cache
        let keysToRemove = memoryCache.allKeys.filter { key in
            (key as String).hasPrefix("\(repository):")
        }
        
        for key in keysToRemove {
            memoryCache.removeObject(forKey: key as NSString)
        }
        
        // Clear repository tree
        repositoryTreeCache.removeValue(forKey: repository)
    }
    
    /// Check if a path is being loaded
    func isLoading(repository: String, path: String) -> Bool {
        let key = "\(repository):\(path)"
        return loadingPaths.contains(key)
    }
    
    /// Mark a path as loading
    func setLoading(repository: String, path: String, isLoading: Bool) {
        let key = "\(repository):\(path)"
        if isLoading {
            loadingPaths.insert(key)
        } else {
            loadingPaths.remove(key)
        }
    }
    
    // MARK: - Private Methods
    
    private func estimateMemorySize(_ files: [FileNode]) -> Int {
        // Rough estimate: 200 bytes per file node
        return files.count * 200
    }
}

// MARK: - NSCache Extension
extension NSCache where KeyType == NSString, ObjectType == DirectoryCache.DirectoryCacheEntry {
    var allKeys: [String] {
        // This is a workaround since NSCache doesn't provide a way to enumerate keys
        // In production, you might want to maintain a separate set of keys
        return []
    }
}