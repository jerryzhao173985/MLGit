import Foundation
import Combine

@MainActor
final class RequestManager {
    private static let _shared = RequestManager()
    
    static var shared: RequestManager {
        return _shared
    }
    
    private var activeRequests: [String: Task<Data, Error>] = [:]
    private var activeFetches: [String: Task<String, Error>] = [:]
    private let requestQueue = DispatchQueue(label: "com.mlgit.requestmanager", attributes: .concurrent)
    // Note: CacheManager is located in Core/Cache/CacheManager.swift
    private let cacheManager = CacheManager.shared
    
    private init() {}
    
    // MARK: - HTML Fetching with Deduplication
    
    func fetchHTML(from url: URL, useCache: Bool = true) async throws -> String {
        let key = url.absoluteString
        
        // Check cache first if enabled
        if useCache {
            if let cachedHTML = await cacheManager.getCachedHTML(for: url) {
                print("RequestManager: Cache hit for \(url)")
                return cachedHTML
            }
        }
        
        // Check if there's already an active request for this URL
        if let existingTask = activeFetches[key] {
            print("RequestManager: Using existing request for \(url)")
            return try await existingTask.value
        }
        
        // Create new task
        let task = Task<String, Error> {
            defer {
                // Clean up when done
                Task { @MainActor [weak self] in
                    self?.activeFetches.removeValue(forKey: key)
                }
            }
            
            do {
                let html = try await NetworkService.shared.fetchHTML(from: url, useCache: false)
                
                // Log HTML for debugging
                HTMLDebugLogger.shared.logHTML(html, for: url, parserType: "RequestManager")
                
                // Cache the result
                if useCache {
                    await self.cacheManager.cacheHTML(html, for: url)
                }
                
                return html
            } catch {
                // Remove from active requests on error
                await MainActor.run {
                    self.activeFetches.removeValue(forKey: key)
                }
                throw error
            }
        }
        
        // Store the task
        activeFetches[key] = task
        
        return try await task.value
    }
    
    // MARK: - Data Fetching with Deduplication
    
    func fetchData(from url: URL, useCache: Bool = true) async throws -> Data {
        let key = url.absoluteString
        
        // Check if there's already an active request for this URL
        if let existingTask = activeRequests[key] {
            print("RequestManager: Using existing data request for \(url)")
            return try await existingTask.value
        }
        
        // Create new task
        let task = Task<Data, Error> {
            defer {
                // Clean up when done
                Task { @MainActor [weak self] in
                    self?.activeRequests.removeValue(forKey: key)
                }
            }
            
            do {
                let data = try await NetworkService.shared.fetchData(from: url, useCache: useCache)
                return data
            } catch {
                // Remove from active requests on error
                await MainActor.run { [weak self] in
                    self?.activeRequests.removeValue(forKey: key)
                }
                throw error
            }
        }
        
        // Store the task
        activeRequests[key] = task
        
        return try await task.value
    }
    
    // MARK: - Cancellation
    
    func cancelAllRequests() {
        print("RequestManager: Cancelling all requests")
        
        // Cancel all active HTML fetches
        for (_, task) in activeFetches {
            task.cancel()
        }
        activeFetches.removeAll()
        
        // Cancel all active data requests
        for (_, task) in activeRequests {
            task.cancel()
        }
        activeRequests.removeAll()
    }
    
    func cancelRequest(for url: URL) {
        let key = url.absoluteString
        
        if let task = activeFetches[key] {
            print("RequestManager: Cancelling HTML request for \(url)")
            task.cancel()
            activeFetches.removeValue(forKey: key)
        }
        
        if let task = activeRequests[key] {
            print("RequestManager: Cancelling data request for \(url)")
            task.cancel()
            activeRequests.removeValue(forKey: key)
        }
    }
    
    // MARK: - Request Status
    
    func isRequestActive(for url: URL) -> Bool {
        let key = url.absoluteString
        return activeFetches[key] != nil || activeRequests[key] != nil
    }
    
    var activeRequestCount: Int {
        activeFetches.count + activeRequests.count
    }
    
    // MARK: - Cache Management
    
    func clearCache() async {
        await cacheManager.clearCache()
    }
}

