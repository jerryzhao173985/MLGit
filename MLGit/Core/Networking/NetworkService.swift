import Foundation
import Combine
import os.log

protocol NetworkServiceProtocol {
    func fetchHTML(from url: URL) async throws -> String
    func fetchData(from url: URL) async throws -> Data
    func fetchHTML(from url: URL, useCache: Bool) async throws -> String
    func fetchData(from url: URL, useCache: Bool) async throws -> Data
}

class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.mlgit", category: "NetworkService")
    private let cache = URLCache(
        memoryCapacity: 50 * 1024 * 1024,
        diskCapacity: 200 * 1024 * 1024,
        diskPath: "com.mlgit.cache"
    )
    
    // Request deduplication
    private var inFlightHTMLRequests: [URL: Task<String, Error>] = [:]
    private var inFlightDataRequests: [URL: Task<Data, Error>] = [:]
    private let requestLock = NSLock()
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        // Set a browser-like User-Agent to avoid server blocking
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        ]
        self.session = URLSession(configuration: configuration)
    }
    
    func fetchHTML(from url: URL) async throws -> String {
        return try await fetchHTML(from: url, useCache: true)
    }
    
    func fetchHTML(from url: URL, useCache: Bool) async throws -> String {
        // Check cache first if enabled
        if useCache, let cachedHTML = await CacheManager.shared.getCachedHTML(for: url) {
            print("Using cached HTML for: \(url.absoluteString)")
            return cachedHTML
        }
        
        // Check for in-flight request
        requestLock.lock()
        if let existingTask = inFlightHTMLRequests[url] {
            requestLock.unlock()
            print("Request deduplication: Using existing request for: \(url.absoluteString)")
            return try await existingTask.value
        }
        
        // Create a new task for this request
        let task = Task<String, Error> {
            print("Fetching HTML from: \(url.absoluteString)")
            
            // Create request with explicit User-Agent
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 30
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("NetworkService: HTTP error \(httpResponse.statusCode) for URL: \(url)")
                
                // Log error response body for debugging
                if let errorBody = String(data: data, encoding: .utf8) {
                    print("NetworkService: Error response body: \(errorBody)")
                    
                    // Log error HTML for debugging
                    Task {
                        HTMLDebugLogger.shared.logHTML(errorBody, for: url, parserType: "NetworkService-Error-\(httpResponse.statusCode)")
                    }
                }
                
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw NetworkError.decodingError
            }
            
            print("Successfully fetched HTML, size: \(data.count) bytes")
            
            // Log HTML for debugging if enabled
            HTMLDebugLogger.shared.logHTML(html, for: url, parserType: "NetworkService")
            
            // Cache the response if caching is enabled
            if useCache {
                await CacheManager.shared.cacheHTML(html, for: url)
            }
            
            return html
        }
        
        // Store the task for deduplication
        inFlightHTMLRequests[url] = task
        requestLock.unlock()
        
        // Execute the task and clean up when done
        do {
            let result = try await task.value
            
            // Remove from in-flight requests
            requestLock.lock()
            inFlightHTMLRequests.removeValue(forKey: url)
            requestLock.unlock()
            
            return result
        } catch {
            // Remove from in-flight requests even if it failed
            requestLock.lock()
            inFlightHTMLRequests.removeValue(forKey: url)
            requestLock.unlock()
            
            throw error
        }
    }
    
    func fetchData(from url: URL) async throws -> Data {
        return try await fetchData(from: url, useCache: true)
    }
    
    func fetchData(from url: URL, useCache: Bool) async throws -> Data {
        // Check for in-flight request
        requestLock.lock()
        if let existingTask = inFlightDataRequests[url] {
            requestLock.unlock()
            logger.debug("Request deduplication: Using existing data request for: \(url.absoluteString)")
            return try await existingTask.value
        }
        
        // Create a new task for this request
        let task = Task<Data, Error> {
            // For binary data, we'll use URLCache instead of our custom cache
            logger.debug("Fetching data from: \(url.absoluteString)")
            
            // Create request with explicit User-Agent
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 30
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            logger.debug("Successfully fetched data, size: \(data.count) bytes")
            return data
        }
        
        // Store the task for deduplication
        inFlightDataRequests[url] = task
        requestLock.unlock()
        
        // Execute the task and clean up when done
        do {
            let result = try await task.value
            
            // Remove from in-flight requests
            requestLock.lock()
            inFlightDataRequests.removeValue(forKey: url)
            requestLock.unlock()
            
            return result
        } catch {
            // Remove from in-flight requests even if it failed
            requestLock.lock()
            inFlightDataRequests.removeValue(forKey: url)
            requestLock.unlock()
            
            throw error
        }
    }
    
    func clearCache() {
        cache.removeAllCachedResponses()
        Task {
            await CacheManager.shared.clearCache()
        }
        logger.info("Cache cleared")
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case noData
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL format. Please check the repository path."
        case .invalidResponse:
            return "Invalid server response. The server may be temporarily unavailable."
        case .httpError(let code):
            switch code {
            case 400:
                return "Bad request. The server couldn't understand the request format."
            case 401:
                return "Authentication required. Please check your credentials."
            case 403:
                return "Access forbidden. You don't have permission to access this resource."
            case 404:
                return "Not found. The repository or file may not exist."
            case 500:
                return "Server error. The git server encountered an internal error."
            case 502:
                return "Bad gateway. The git server is having connectivity issues."
            case 503:
                return "Service unavailable. The git server is temporarily down."
            default:
                return "HTTP error \(code). Please try again later."
            }
        case .decodingError:
            return "Failed to decode response. The server returned unexpected data."
        case .noData:
            return "No data received from server. Please check your connection."
        case .parsingError(let message):
            return "Failed to parse git data: \(message)"
        }
    }
}