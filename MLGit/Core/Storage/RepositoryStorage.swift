import Foundation
import Combine

@MainActor
final class RepositoryStorage: ObservableObject {
    private static let _shared = RepositoryStorage()
    
    static var shared: RepositoryStorage {
        return _shared
    }
    
    @Published private(set) var repositories: [Project] = []
    @Published private(set) var lastUpdated: Date?
    
    private let storageURL: URL
    private let updateInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {
        // Get documents directory for persistent storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        storageURL = documentsPath.appendingPathComponent("repositories.json")
        
        // Load stored repositories on init
        loadStoredRepositories()
    }
    
    // MARK: - Public Methods
    
    /// Get all repositories, loading from storage or network as needed
    func getRepositories() async -> [Project] {
        // If we have repositories and they're recent, return them
        if !repositories.isEmpty, let lastUpdated = lastUpdated,
           Date().timeIntervalSince(lastUpdated) < updateInterval {
            print("RepositoryStorage: Returning cached repositories (last updated: \(lastUpdated))")
            return repositories
        }
        
        // Otherwise, fetch from network
        do {
            let projects = try await GitService.shared.fetchProjects()
            await updateRepositories(projects)
            return projects
        } catch {
            print("RepositoryStorage: Failed to fetch from network, returning stored data")
            return repositories
        }
    }
    
    /// Force refresh repositories from network
    func refreshRepositories() async throws {
        let projects = try await GitService.shared.fetchProjects()
        await updateRepositories(projects)
    }
    
    /// Update stored repositories
    func updateRepositories(_ projects: [Project]) async {
        self.repositories = projects
        self.lastUpdated = Date()
        saveRepositories()
    }
    
    /// Check if repositories need update
    var needsUpdate: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) >= updateInterval
    }
    
    /// Get repository by path
    func repository(for path: String) -> Project? {
        return repositories.first { $0.path == path }
    }
    
    // MARK: - Private Methods
    
    private func loadStoredRepositories() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else {
            print("RepositoryStorage: No stored repositories found")
            return
        }
        
        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let stored = try decoder.decode(StoredRepositories.self, from: data)
            self.repositories = stored.repositories
            self.lastUpdated = stored.lastUpdated
            
            print("RepositoryStorage: Loaded \(repositories.count) repositories from storage")
        } catch {
            print("RepositoryStorage: Failed to load stored repositories: \(error)")
        }
    }
    
    private func saveRepositories() {
        let stored = StoredRepositories(
            repositories: repositories,
            lastUpdated: lastUpdated ?? Date()
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(stored)
            try data.write(to: storageURL)
            
            print("RepositoryStorage: Saved \(repositories.count) repositories to storage")
        } catch {
            print("RepositoryStorage: Failed to save repositories: \(error)")
        }
    }
}

// MARK: - Storage Model

private struct StoredRepositories: Codable {
    let repositories: [Project]
    let lastUpdated: Date
}

// MARK: - Extensions

extension RepositoryStorage {
    /// Get categories from stored repositories
    var categories: [String] {
        let allCategories = repositories.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }
    
    /// Search repositories
    func searchRepositories(query: String, category: String? = nil) -> [Project] {
        var filtered = repositories
        
        // Filter by category if specified
        if let category = category {
            filtered = filtered.filter { $0.displayCategory == category }
        }
        
        // Filter by search query
        if !query.isEmpty {
            let lowercaseQuery = query.lowercased()
            filtered = filtered.filter { project in
                project.name.lowercased().contains(lowercaseQuery) ||
                project.path.lowercased().contains(lowercaseQuery) ||
                (project.description?.lowercased().contains(lowercaseQuery) ?? false)
            }
        }
        
        return filtered
    }
}