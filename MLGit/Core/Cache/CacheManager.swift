import Foundation
import Combine

@MainActor
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    private let cacheDirectory: URL
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100 MB
    
    // Memory cache for frequently accessed data
    private var memoryCache = NSCache<NSString, CacheEntry>()
    
    private init() {
        // Create cache directory
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("MLGitCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 10 * 1024 * 1024 // 10 MB
        
        // Clean expired cache on startup
        Task {
            await cleanExpiredCache()
        }
    }
    
    // MARK: - Public Methods
    
    func cacheHTML(_ html: String, for url: URL) async {
        let key = cacheKey(for: url)
        let entry = CacheEntry(data: html.data(using: .utf8)!, timestamp: Date())
        
        // Memory cache
        memoryCache.setObject(entry, forKey: key as NSString)
        
        // Disk cache
        let fileURL = cacheFileURL(for: key)
        try? entry.data.write(to: fileURL)
        
        // Save metadata
        saveCacheMetadata(for: key, timestamp: entry.timestamp)
    }
    
    func getCachedHTML(for url: URL) async -> String? {
        let key = cacheKey(for: url)
        
        // Check memory cache first
        if let entry = memoryCache.object(forKey: key as NSString) {
            if !isExpired(entry.timestamp) {
                return String(data: entry.data, encoding: .utf8)
            } else {
                memoryCache.removeObject(forKey: key as NSString)
            }
        }
        
        // Check disk cache
        let fileURL = cacheFileURL(for: key)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let timestamp = getCacheMetadata(for: key),
              !isExpired(timestamp) else {
            return nil
        }
        
        // Read file asynchronously
        do {
            let data = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let fileData = try Data(contentsOf: fileURL)
                        continuation.resume(returning: fileData)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            // Load into memory cache
            let entry = CacheEntry(data: data, timestamp: timestamp)
            memoryCache.setObject(entry, forKey: key as NSString)
            
            return html
        } catch {
            // If reading fails, return nil
            return nil
        }
    }
    
    func cacheData<T: Codable>(_ object: T, for key: String) async {
        guard let data = try? JSONEncoder().encode(object) else { return }
        
        let entry = CacheEntry(data: data, timestamp: Date())
        memoryCache.setObject(entry, forKey: key as NSString)
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        try? data.write(to: fileURL)
        
        saveCacheMetadata(for: key, timestamp: entry.timestamp)
    }
    
    func getCachedData<T: Codable>(_ type: T.Type, for key: String) async -> T? {
        // Check memory cache
        if let entry = memoryCache.object(forKey: key as NSString) {
            if !isExpired(entry.timestamp) {
                return try? JSONDecoder().decode(type, from: entry.data)
            } else {
                memoryCache.removeObject(forKey: key as NSString)
            }
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let timestamp = getCacheMetadata(for: key),
              !isExpired(timestamp) else {
            return nil
        }
        
        // Read file asynchronously
        do {
            let data = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let fileData = try Data(contentsOf: fileURL)
                        continuation.resume(returning: fileData)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        
            // Load into memory cache
            let entry = CacheEntry(data: data, timestamp: timestamp)
            memoryCache.setObject(entry, forKey: key as NSString)
            
            return try? JSONDecoder().decode(type, from: data)
        } catch {
            // If reading fails, return nil
            return nil
        }
    }
    
    func clearCache() async {
        memoryCache.removeAllObjects()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
        
        UserDefaults.standard.removeObject(forKey: "MLGitCacheMetadata")
    }
    
    func getCacheSize() async -> Int64 {
        var size: Int64 = 0
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                size += Int64(attributes.fileSize ?? 0)
            }
        } catch {
            print("Failed to calculate cache size: \(error)")
        }
        
        return size
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for url: URL) -> String {
        return url.absoluteString.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
    }
    
    private func cacheFileURL(for key: String) -> URL {
        return cacheDirectory.appendingPathComponent("\(key).html")
    }
    
    private func isExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > cacheExpirationInterval
    }
    
    private func saveCacheMetadata(for key: String, timestamp: Date) {
        var metadata = UserDefaults.standard.dictionary(forKey: "MLGitCacheMetadata") ?? [:]
        metadata[key] = timestamp.timeIntervalSince1970
        UserDefaults.standard.set(metadata, forKey: "MLGitCacheMetadata")
    }
    
    private func getCacheMetadata(for key: String) -> Date? {
        guard let metadata = UserDefaults.standard.dictionary(forKey: "MLGitCacheMetadata"),
              let timestamp = metadata[key] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    private func cleanExpiredCache() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            var metadata = UserDefaults.standard.dictionary(forKey: "MLGitCacheMetadata") ?? [:]
            
            for file in files {
                let key = file.deletingPathExtension().lastPathComponent
                if let timestamp = getCacheMetadata(for: key), isExpired(timestamp) {
                    try FileManager.default.removeItem(at: file)
                    metadata.removeValue(forKey: key)
                    memoryCache.removeObject(forKey: key as NSString)
                }
            }
            
            UserDefaults.standard.set(metadata, forKey: "MLGitCacheMetadata")
            
            // Check cache size and remove oldest files if needed
            let currentSize = await getCacheSize()
            if currentSize > maxCacheSize {
                await trimCache(to: maxCacheSize / 2)
            }
        } catch {
            print("Failed to clean cache: \(error)")
        }
    }
    
    private func trimCache(to targetSize: Int64) async {
        do {
            var files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            
            // Sort by creation date (oldest first)
            files.sort { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
                return date1 < date2
            }
            
            var currentSize = await getCacheSize()
            var metadata = UserDefaults.standard.dictionary(forKey: "MLGitCacheMetadata") ?? [:]
            
            for file in files {
                if currentSize <= targetSize { break }
                
                let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = Int64(attributes.fileSize ?? 0)
                
                try FileManager.default.removeItem(at: file)
                currentSize -= fileSize
                
                let key = file.deletingPathExtension().lastPathComponent
                metadata.removeValue(forKey: key)
                memoryCache.removeObject(forKey: key as NSString)
            }
            
            UserDefaults.standard.set(metadata, forKey: "MLGitCacheMetadata")
        } catch {
            print("Failed to trim cache: \(error)")
        }
    }
}

// MARK: - Cache Entry

private class CacheEntry: NSObject {
    let data: Data
    let timestamp: Date
    
    init(data: Data, timestamp: Date) {
        self.data = data
        self.timestamp = timestamp
        super.init()
    }
}

// MARK: - URLSession Extension for Caching

extension URLSession {
    func cachedData(from url: URL) async throws -> Data {
        // Check cache first
        if let cachedHTML = await CacheManager.shared.getCachedHTML(for: url),
           let data = cachedHTML.data(using: .utf8) {
            return data
        }
        
        // Fetch from network
        let (data, _) = try await self.data(from: url)
        
        // Cache the response
        if let html = String(data: data, encoding: .utf8) {
            await CacheManager.shared.cacheHTML(html, for: url)
        }
        
        return data
    }
}