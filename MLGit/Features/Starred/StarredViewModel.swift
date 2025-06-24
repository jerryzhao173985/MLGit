import Foundation
import SwiftUI
import Combine
import GitHTMLParser

struct ProjectUpdate: Codable {
    let projectId: String
    let lastCommitSha: String
    let lastCommitMessage: String
    let lastCommitDate: Date
    let hasNewCommits: Bool
    let lastChecked: Date
}

@MainActor
class StarredViewModel: ObservableObject {
    @Published var starredProjects: [Project] = []
    @Published var projectUpdates: [String: ProjectUpdate] = [:] // projectId -> update info
    @Published var isCheckingUpdates = false
    
    private let userDefaults = UserDefaults.standard
    private let starredKey = "starredProjects"
    private let updatesKey = "starredProjectUpdates"
    private let lastCheckedKey = "lastUpdateCheck"
    private let gitService = GitService.shared
    
    func loadStarredProjects() {
        if let data = userDefaults.data(forKey: starredKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            starredProjects = decoded
        }
        
        // Load cached updates
        if let updatesData = userDefaults.data(forKey: updatesKey),
           let updates = try? JSONDecoder().decode([String: ProjectUpdate].self, from: updatesData) {
            projectUpdates = updates
        }
    }
    
    func addStarred(_ project: Project) {
        if !starredProjects.contains(where: { $0.id == project.id }) {
            starredProjects.append(project)
            saveStarredProjects()
        }
    }
    
    func removeStarred(at offsets: IndexSet) {
        starredProjects.remove(atOffsets: offsets)
        saveStarredProjects()
    }
    
    func removeStarred(_ project: Project) {
        starredProjects.removeAll { $0.id == project.id }
        saveStarredProjects()
    }
    
    func isStarred(_ project: Project) -> Bool {
        starredProjects.contains { $0.id == project.id }
    }
    
    func toggleStarred(_ project: Project) {
        if isStarred(project) {
            removeStarred(project)
        } else {
            addStarred(project)
        }
    }
    
    private func saveStarredProjects() {
        if let encoded = try? JSONEncoder().encode(starredProjects) {
            userDefaults.set(encoded, forKey: starredKey)
        }
    }
    
    private func saveProjectUpdates() {
        if let encoded = try? JSONEncoder().encode(projectUpdates) {
            userDefaults.set(encoded, forKey: updatesKey)
        }
    }
    
    func checkForUpdates() async {
        guard !isCheckingUpdates else { return }
        
        isCheckingUpdates = true
        defer { isCheckingUpdates = false }
        
        for project in starredProjects {
            do {
                // Fetch latest commit for the project
                let commits = try await gitService.fetchCommits(repositoryPath: project.path, offset: 0)
                if let latestCommit = commits.commits.first {
                    let previousUpdate = projectUpdates[project.id]
                    let hasNewCommits = previousUpdate?.lastCommitSha != latestCommit.sha
                    
                    let update = ProjectUpdate(
                        projectId: project.id,
                        lastCommitSha: latestCommit.sha,
                        lastCommitMessage: latestCommit.message,
                        lastCommitDate: latestCommit.date,
                        hasNewCommits: hasNewCommits,
                        lastChecked: Date()
                    )
                    
                    projectUpdates[project.id] = update
                }
            } catch {
                print("Failed to check updates for \(project.name): \(error)")
            }
        }
        
        saveProjectUpdates()
        userDefaults.set(Date(), forKey: lastCheckedKey)
    }
    
    func hasNewCommits(for project: Project) -> Bool {
        return projectUpdates[project.id]?.hasNewCommits ?? false
    }
    
    func getLastCommitInfo(for project: Project) -> (message: String, date: Date)? {
        guard let update = projectUpdates[project.id] else { return nil }
        return (update.lastCommitMessage, update.lastCommitDate)
    }
    
    func markAsViewed(_ project: Project) {
        if var update = projectUpdates[project.id] {
            update = ProjectUpdate(
                projectId: update.projectId,
                lastCommitSha: update.lastCommitSha,
                lastCommitMessage: update.lastCommitMessage,
                lastCommitDate: update.lastCommitDate,
                hasNewCommits: false,
                lastChecked: update.lastChecked
            )
            projectUpdates[project.id] = update
            saveProjectUpdates()
        }
    }
    
    var lastUpdateCheck: Date? {
        userDefaults.object(forKey: lastCheckedKey) as? Date
    }
    
    var shouldCheckForUpdates: Bool {
        guard let lastCheck = lastUpdateCheck else { return true }
        // Check if more than 30 minutes have passed
        return Date().timeIntervalSince(lastCheck) > 1800
    }
}