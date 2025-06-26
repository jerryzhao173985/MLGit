import Foundation
import SwiftUI

struct CommitsView: View {
    let repositoryPath: String
    @StateObject private var viewModel: CommitsViewModel
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self._viewModel = StateObject(wrappedValue: CommitsViewModel(repositoryPath: repositoryPath))
    }
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.commits.isEmpty {
                CommitListSkeletonView()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            } else {
                ForEach(viewModel.commits) { commit in
                    NavigationLink(destination: CommitDetailView(
                        repositoryPath: repositoryPath,
                        commitSHA: commit.sha
                    )) {
                        CommitRowView(commit: commit)
                    }
                    .listRowHaptic()
                }
                .opacity(viewModel.isLoading ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                
                if viewModel.hasMore {
                    HStack {
                        Spacer()
                        if viewModel.isLoadingMore {
                            ProgressView()
                        } else {
                            Button("Load More") {
                                Task {
                                    await viewModel.loadMoreCommits()
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .listRowSeparator(.hidden)
                }
            }
        }
        .refreshable {
            await viewModel.loadCommits()
        }
        .task {
            await viewModel.loadCommits()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
}

struct CommitRowView: View {
    let commit: CommitSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(commit.shortMessage)
                .font(.system(.body, design: .monospaced))
                .lineLimit(2)
            
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(commit.authorName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(commit.displayDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(commit.shortSHA)
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct CommitsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommitsView(repositoryPath: "tosa/reference_model.git")
        }
    }
}
