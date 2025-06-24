import Foundation
import SwiftUI

struct CommitDetailView: View {
    let repositoryPath: String
    let commitSHA: String
    @StateObject private var viewModel: CommitDetailViewModel
    @State private var showingPatch = false
    
    init(repositoryPath: String, commitSHA: String) {
        self.repositoryPath = repositoryPath
        self.commitSHA = commitSHA
        self._viewModel = StateObject(wrappedValue: CommitDetailViewModel(
            repositoryPath: repositoryPath,
            commitSHA: commitSHA
        ))
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading commit...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else if let commit = viewModel.commitDetail {
                VStack(alignment: .leading, spacing: 20) {
                    CommitHeaderView(commit: commit)
                        .padding(.horizontal)
                    
                    Divider()
                    
                    CommitMessageView(message: commit.message)
                        .padding(.horizontal)
                    
                    if let stats = commit.diffStats {
                        DiffStatsView(stats: stats)
                            .padding(.horizontal)
                    }
                    
                    if !commit.changedFiles.isEmpty {
                        ChangedFilesView(files: commit.changedFiles)
                    }
                    
                    Button(action: { showingPatch = true }) {
                        Label("View Patch", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Commit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ShareLink(item: commitSHA) {
                        Label("Share SHA", systemImage: "square.and.arrow.up")
                    }
                    Button(action: copyCommitSHA) {
                        Label("Copy SHA", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingPatch) {
            NavigationView {
                PatchView(
                    repositoryPath: repositoryPath,
                    commitSHA: commitSHA
                )
            }
        }
        .task {
            await viewModel.loadCommit()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    private func copyCommitSHA() {
        UIPasteboard.general.string = commitSHA
    }
}

struct CommitHeaderView: View {
    let commit: CommitDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(commit.sha.prefix(12)))
                .font(.system(.title3, design: .monospaced))
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    VStack(alignment: .leading) {
                        Text(commit.authorName)
                            .fontWeight(.medium)
                        if let email = commit.authorEmail {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                }
                
                Label(commit.authorDate.formatted(), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !commit.parents.isEmpty {
                    Label("Parents: \(commit.parents.joined(separator: ", "))", systemImage: "arrow.triangle.branch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct CommitMessageView: View {
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Commit Message")
                .font(.headline)
            
            Text(message)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

struct DiffStatsView: View {
    let stats: DiffStats
    
    var body: some View {
        HStack(spacing: 16) {
            StatBadge(
                value: stats.filesChanged,
                label: stats.filesChanged == 1 ? "file" : "files",
                color: .blue
            )
            
            StatBadge(
                value: stats.insertions,
                label: stats.insertions == 1 ? "addition" : "additions",
                color: .green
            )
            
            StatBadge(
                value: stats.deletions,
                label: stats.deletions == 1 ? "deletion" : "deletions",
                color: .red
            )
        }
    }
}

struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text("+\(value)")
                .fontWeight(.medium)
            Text(label)
                .font(.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct ChangedFilesView: View {
    let files: [ChangedFile]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Changed Files")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(files) { file in
                ChangedFileRow(file: file)
                    .padding(.horizontal)
            }
        }
    }
}

struct ChangedFileRow: View {
    let file: ChangedFile
    
    var body: some View {
        HStack {
            Image(systemName: fileIcon)
                .foregroundColor(fileColor)
                .frame(width: 20)
            
            Text(file.path)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 4) {
                if file.additions > 0 {
                    Text("+\(file.additions)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                if file.deletions > 0 {
                    Text("-\(file.deletions)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var fileIcon: String {
        switch file.changeType {
        case .added:
            return "plus.circle.fill"
        case .modified:
            return "pencil.circle.fill"
        case .deleted:
            return "minus.circle.fill"
        case .renamed:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .copied:
            return "doc.on.doc.fill"
        }
    }
    
    private var fileColor: Color {
        switch file.changeType {
        case .added:
            return .green
        case .modified:
            return .orange
        case .deleted:
            return .red
        case .renamed:
            return .blue
        case .copied:
            return .purple
        }
    }
}

struct CommitDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommitDetailView(
                repositoryPath: "tosa/reference_model.git",
                commitSHA: "cd167baf693b155805622e340008388cc89f61b2"
            )
        }
    }
}
