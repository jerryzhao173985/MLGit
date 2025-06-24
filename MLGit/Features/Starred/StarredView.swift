import Foundation
import SwiftUI

struct StarredView: View {
    @StateObject private var viewModel = StarredViewModel()
    @State private var showingError = false
    
    var body: some View {
        Group {
            if viewModel.starredProjects.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "star")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No starred projects")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Star projects to see them here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.starredProjects) { project in
                        NavigationLink(destination: RepositoryView(repositoryPath: project.path)) {
                            ProjectRowView(project: project)
                        }
                    }
                    .onDelete(perform: viewModel.removeStarred)
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
        }
    }
}

struct StarredView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StarredView()
        }
    }
}
