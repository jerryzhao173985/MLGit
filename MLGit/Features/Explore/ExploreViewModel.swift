import Foundation
import Combine

@MainActor
class ExploreViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let gitService = GitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var categories: [String] {
        let allCategories = projects.map { $0.displayCategory }
        return Array(Set(allCategories)).sorted()
    }
    
    init() {
        gitService.$error
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    func loadProjects() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            projects = try await gitService.fetchProjects()
            error = nil
        } catch {
            self.error = error
            // Keep existing projects if we have them
            if projects.isEmpty {
                projects = []
            }
        }
    }
}