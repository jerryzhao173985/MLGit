import Foundation
import SwiftUI

struct StarredView: View {
    @StateObject private var viewModel = StarredViewModel()
    @State private var showingError = false
    @State private var isRefreshing = false
    
    var body: some View {
        Group {
            if viewModel.starredProjects.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "No Starred Projects",
                    message: "Star projects to see them here"
                )
            } else {
                List {
                    if let lastCheck = viewModel.lastUpdateCheck {
                        HStack {
                            Text("Last checked: \(lastCheck, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if viewModel.isCheckingUpdates {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    
                    ForEach(viewModel.starredProjects) { project in
                        NavigationLink(destination: LazyRepositoryView(repositoryPath: project.path)) {
                            StarredProjectRowView(project: project, viewModel: viewModel)
                        }
                        .onTapGesture {
                            viewModel.markAsViewed(project)
                        }
                    }
                    .onDelete(perform: viewModel.removeStarred)
                }
                .refreshable {
                    await viewModel.checkForUpdates()
                }
            }
        }
        .navigationTitle("Starred")
        .toolbar {
            if !viewModel.starredProjects.isEmpty {
                EditButton()
            }
        }
        .onAppear {
            viewModel.loadStarredProjects()
            if viewModel.shouldCheckForUpdates {
                Task {
                    await viewModel.checkForUpdates()
                }
            }
        }
    }
}

struct StarredProjectRowView: View {
    let project: Project
    @ObservedObject var viewModel: StarredViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                    
                    if viewModel.hasNewCommits(for: project) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                }
                
                if let description = project.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let commitInfo = viewModel.getLastCommitInfo(for: project) {
                    HStack {
                        Text(commitInfo.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(commitInfo.date, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StarredView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StarredView()
        }
    }
}