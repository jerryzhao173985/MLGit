import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedTheme: Theme = .system
    @Published var cacheSize: String = "Calculating..."
    @Published var starredCount: Int = 0
    @Published var notesCount: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    init() {
        loadTheme()
    }
    
    func loadStats() {
        calculateCacheSize()
        loadStarredCount()
        loadNotesCount()
    }
    
    func updateTheme(_ theme: Theme) {
        selectedTheme = theme
        userDefaults.set(theme.rawValue, forKey: themeKey)
    }
    
    func clearCache() {
        NetworkService.shared.clearCache()
        URLCache.shared.removeAllCachedResponses()
        calculateCacheSize()
    }
    
    func resetAllData() {
        clearCache()
        
        userDefaults.removeObject(forKey: "starredProjects")
        userDefaults.removeObject(forKey: "notes")
        userDefaults.removeObject(forKey: themeKey)
        
        loadStats()
        loadTheme()
    }
    
    private func loadTheme() {
        if let themeString = userDefaults.string(forKey: themeKey),
           let theme = Theme(rawValue: themeString) {
            selectedTheme = theme
        }
    }
    
    private func calculateCacheSize() {
        Task {
            let fileManager = FileManager.default
            let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            
            do {
                let size = try await calculateDirectorySize(at: cacheDirectory)
                await MainActor.run {
                    self.cacheSize = formatBytes(size)
                }
            } catch {
                await MainActor.run {
                    self.cacheSize = "Unknown"
                }
            }
        }
    }
    
    private func calculateDirectorySize(at url: URL) async throws -> Int64 {
        let fileManager = FileManager.default
        var size: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                size += Int64(fileSize)
            }
        }
        
        return size
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func loadStarredCount() {
        if let data = userDefaults.data(forKey: "starredProjects"),
           let projects = try? JSONDecoder().decode([Project].self, from: data) {
            starredCount = projects.count
        } else {
            starredCount = 0
        }
    }
    
    private func loadNotesCount() {
        if let data = userDefaults.data(forKey: "notes"),
           let notes = try? JSONDecoder().decode([Note].self, from: data) {
            notesCount = notes.count
        } else {
            notesCount = 0
        }
    }
}