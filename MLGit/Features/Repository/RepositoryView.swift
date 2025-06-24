import Foundation
import SwiftUI

struct RepositoryView: View {
    let repositoryPath: String
    @StateObject private var viewModel: RepositoryViewModel
    @StateObject private var starredViewModel = StarredViewModel()
    @State private var selectedTab = 0
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self._viewModel = StateObject(wrappedValue: RepositoryViewModel(repositoryPath: repositoryPath))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.repository == nil {
                ProgressView("Loading repository...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let repository = viewModel.repository {
                TabView(selection: $selectedTab) {
                    AboutView(repository: repository)
                        .tabItem {
                            Label("About", systemImage: "doc.text")
                        }
                        .tag(0)
                    
                    CodeView(repositoryPath: repositoryPath)
                        .tabItem {
                            Label("Code", systemImage: "doc.text.below.ecg")
                        }
                        .tag(1)
                    
                    CommitsView(repositoryPath: repositoryPath)
                        .tabItem {
                            Label("Commits", systemImage: "clock")
                        }
                        .tag(2)
                    
                    RefsView(repositoryPath: repositoryPath)
                        .tabItem {
                            Label("Branches", systemImage: "arrow.triangle.branch")
                        }
                        .tag(3)
                }
                .navigationTitle(repository.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: toggleStar) {
                            Image(systemName: isStarred ? "star.fill" : "star")
                                .foregroundColor(isStarred ? .yellow : .primary)
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadRepository()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    private var isStarred: Bool {
        guard let repository = viewModel.repository else { return false }
        let project = Project(
            id: repository.id,
            name: repository.name,
            path: repository.path,
            description: repository.description,
            lastActivity: repository.lastUpdate,
            category: nil
        )
        return starredViewModel.isStarred(project)
    }
    
    private func toggleStar() {
        guard let repository = viewModel.repository else { return }
        let project = Project(
            id: repository.id,
            name: repository.name,
            path: repository.path,
            description: repository.description,
            lastActivity: repository.lastUpdate,
            category: nil
        )
        starredViewModel.toggleStarred(project)
    }
}

struct RepositoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RepositoryView(repositoryPath: "tosa/reference_model.git")
        }
    }
}
