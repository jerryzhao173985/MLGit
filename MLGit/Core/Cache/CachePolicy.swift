import Foundation

/// Cache policy configuration for different types of data
enum CachePolicy {
    case repositoryList
    case repositoryDetail
    case commitHistory
    case fileContent
    case treeStructure
    case refs
    case summary
    case about
    case custom(TimeInterval)
    
    /// Get the cache expiration interval for each policy
    var expirationInterval: TimeInterval {
        switch self {
        case .repositoryList:
            // Repository list rarely changes
            return 7 * 24 * 60 * 60 // 7 days
            
        case .repositoryDetail:
            // Repository details may update daily
            return 24 * 60 * 60 // 24 hours
            
        case .commitHistory:
            // Commits update moderately frequently
            return 12 * 60 * 60 // 12 hours
            
        case .fileContent:
            // File content may change more often
            return 60 * 60 // 1 hour
            
        case .treeStructure:
            // Directory structure changes infrequently
            return 24 * 60 * 60 // 24 hours
            
        case .refs:
            // Branches and tags update occasionally
            return 4 * 60 * 60 // 4 hours
            
        case .summary:
            // Summary page updates with commits
            return 2 * 60 * 60 // 2 hours
            
        case .about:
            // About/readme rarely changes
            return 48 * 60 * 60 // 48 hours
            
        case .custom(let interval):
            return interval
        }
    }
    
    /// Get cache policy based on URL
    static func policy(for url: URL) -> CachePolicy {
        let path = url.path
        
        if path.contains("/tree/") {
            return .treeStructure
        } else if path.contains("/blob/") || path.contains("/plain/") {
            return .fileContent
        } else if path.contains("/log/") {
            return .commitHistory
        } else if path.contains("/refs/") {
            return .refs
        } else if path.contains("/about/") {
            return .about
        } else if path.contains("/summary") || path.hasSuffix(".git/") {
            return .summary
        } else if !path.contains(".git") {
            // Root catalog page
            return .repositoryList
        } else {
            // Default for repository pages
            return .repositoryDetail
        }
    }
}

/// Extended cache entry with policy support
class PolicyCacheEntry {
    let data: Data
    let timestamp: Date
    let policy: CachePolicy
    
    init(data: Data, timestamp: Date, policy: CachePolicy) {
        self.data = data
        self.timestamp = timestamp
        self.policy = policy
    }
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > policy.expirationInterval
    }
    
    var timeUntilExpiration: TimeInterval {
        let elapsed = Date().timeIntervalSince(timestamp)
        return max(0, policy.expirationInterval - elapsed)
    }
}