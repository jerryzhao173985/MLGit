import Foundation
import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingError = false
    
    var body: some View {
        List {
            listContent
        }
        .searchable(text: $searchText, prompt: "Search projects")
        .navigationTitle("Explore")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("All Categories") {
                        selectedCategory = nil
                    }
                    Divider()
                    ForEach(viewModel.categories, id: \.self) { category in
                        Button(category) {
                            selectedCategory = category
                        }
                    }
                } label: {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                }
            }
        }
        .refreshable {
            await viewModel.loadProjects()
        }
        .task {
            if networkMonitor.isConnected && viewModel.projects.isEmpty {
                await viewModel.loadProjects()
            }
        }
        .onReceive(viewModel.$error) { error in
            showingError = error != nil
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    @ViewBuilder
    private var listContent: some View {
        if !networkMonitor.isConnected {
            NoConnectionView()
                .listRowSeparator(.hidden)
        } else if viewModel.isLoading && viewModel.projects.isEmpty {
            LoadingSkeletonView()
                .listRowSeparator(.hidden)
        } else if let error = viewModel.error {
            ErrorStateView(error: error) {
                Task {
                    await viewModel.loadProjects()
                }
            }
            .listRowSeparator(.hidden)
        } else if viewModel.projects.isEmpty && !viewModel.isLoading {
            EmptyStateView(
                icon: "folder",
                title: "No Repositories Found",
                message: "No repositories are available at this time.",
                actionTitle: "Refresh",
                action: {
                    Task {
                        await viewModel.loadProjects()
                    }
                }
            )
            .listRowSeparator(.hidden)
        } else {
            projectsList
        }
    }
    
    
    private var projectsList: some View {
        ForEach(filteredProjects) { project in
            NavigationLink(destination: RepositoryView(repositoryPath: project.path)) {
                ProjectRowView(project: project)
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    private var filteredProjects: [Project] {
        var filtered = viewModel.projects
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.displayCategory == category }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.description?.localizedCaseInsensitiveContains(searchText) == true ||
                project.path.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                if let lastActivity = project.lastActivity {
                    Text(lastActivity, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let description = project.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Label(project.displayCategory, systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExploreView()
                .environmentObject(NetworkMonitor.shared)
        }
    }
}
