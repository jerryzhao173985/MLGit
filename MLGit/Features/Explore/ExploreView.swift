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
            noConnectionView
        } else if viewModel.isLoading && viewModel.projects.isEmpty {
            loadingView
        } else if viewModel.projects.isEmpty && !viewModel.isLoading {
            emptyStateView
        } else {
            projectsList
        }
    }
    
    private var noConnectionView: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(.orange)
            Text("No internet connection")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowSeparator(.hidden)
        .padding(.vertical)
    }
    
    private var loadingView: some View {
        ProgressView("Loading projects...")
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowSeparator(.hidden)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No projects found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Pull to refresh")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowSeparator(.hidden)
        .padding(.vertical)
    }
    
    private var projectsList: some View {
        ForEach(filteredProjects) { project in
            NavigationLink(destination: RepositoryView(repositoryPath: project.path)) {
                ProjectRowView(project: project)
            }
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
