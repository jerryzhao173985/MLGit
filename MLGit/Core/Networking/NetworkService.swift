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
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        configuration.httpAdditionalHeaders = [
            "User-Agent": "MLGit-iOS/1.0"
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
        
        print("Fetching HTML from: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("NetworkService: HTTP error \(httpResponse.statusCode) for URL: \(url)")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingError
        }
        
        print("Successfully fetched HTML, size: \(data.count) bytes")
        
        // Cache the response if caching is enabled
        if useCache {
            await CacheManager.shared.cacheHTML(html, for: url)
        }
        
        return html
    }
    
    func fetchData(from url: URL) async throws -> Data {
        return try await fetchData(from: url, useCache: true)
    }
    
    func fetchData(from url: URL, useCache: Bool) async throws -> Data {
        // For binary data, we'll use URLCache instead of our custom cache
        logger.debug("Fetching data from: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        logger.debug("Successfully fetched data, size: \(data.count) bytes")
        return data
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
    case httpError(statusCode: Int)
    case decodingError
    case noData
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let statusCode):
            return statusCode == 404 ? "Repository not found" : "HTTP error: \(statusCode)"
        case .decodingError:
            return "Failed to decode response"
        case .noData:
            return "No data received"
        case .parsingError(let message):
            return "Failed to parse response: \(message)"
        }
    }
}