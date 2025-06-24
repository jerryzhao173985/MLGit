import Foundation
import SwiftUI
import Combine

@MainActor
class StarredViewModel: ObservableObject {
    @Published var starredProjects: [Project] = []
    
    private let userDefaults = UserDefaults.standard
    private let starredKey = "starredProjects"
    
    func loadStarredProjects() {
        if let data = userDefaults.data(forKey: starredKey),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            starredProjects = decoded
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
}