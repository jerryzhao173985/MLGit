import SwiftUI
import GitHTMLParser
import Combine

struct SummaryView: View {
    let repositoryPath: String
    @StateObject private var viewModel: SummaryViewModel
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self._viewModel = StateObject(wrappedValue: SummaryViewModel(repositoryPath: repositoryPath))
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.summary == nil {
                LoadingStateView(title: "Loading summary...")
            } else if let error = viewModel.error {
                ErrorStateView(error: error) {
                    Task {
                        await viewModel.loadSummary()
                    }
                }
            } else if let summary = viewModel.summary {
                VStack(alignment: .leading, spacing: 20) {
                    // Repository Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(summary.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let description = summary.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Stats
                    HStack(spacing: 30) {
                        StatView(value: summary.branches, label: "Branches", icon: "arrow.triangle.branch")
                        StatView(value: summary.tags, label: "Tags", icon: "tag")
                        StatView(value: summary.contributors, label: "Contributors", icon: "person.2")
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Clone URLs
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Clone")
                            .font(.headline)
                        
                        ForEach(summary.cloneURLs, id: \.url) { cloneURL in
                            CloneURLView(cloneURL: cloneURL)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let lastCommit = summary.lastCommit {
                        Divider()
                        
                        // Last Commit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Latest Commit")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lastCommit.message)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                
                                HStack {
                                    Text(lastCommit.author)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(lastCommit.date, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(lastCommit.sha.prefix(7))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
        }
        .refreshable {
            await viewModel.loadSummary()
        }
        .task {
            await viewModel.loadSummary()
        }
    }
}

struct StatView: View {
    let value: Int
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text("\(value)")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CloneURLView: View {
    let cloneURL: RepositorySummary.CloneURL
    @State private var copied = false
    
    var body: some View {
        HStack {
            Label(cloneURL.type.rawValue, systemImage: iconForType(cloneURL.type))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(cloneURL.url)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            Button(action: copyToClipboard) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(copied ? .green : .accentColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func iconForType(_ type: RepositorySummary.CloneURL.URLType) -> String {
        switch type {
        case .https:
            return "lock"
        case .ssh:
            return "key"
        case .git:
            return "network"
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = cloneURL.url
        copied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

@MainActor
class SummaryViewModel: ObservableObject {
    @Published var summary: RepositorySummary?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let gitService = GitService.shared
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
    }
    
    func loadSummary() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            summary = try await gitService.fetchRepositorySummary(repositoryPath: repositoryPath)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView(repositoryPath: "tosa/reference_model.git")
    }
}