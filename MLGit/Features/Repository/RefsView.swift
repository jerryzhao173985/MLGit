import Foundation
import SwiftUI

struct RefsView: View {
    let repositoryPath: String
    @StateObject private var viewModel: RefsViewModel
    @State private var selectedSegment = 0
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self._viewModel = StateObject(wrappedValue: RefsViewModel(repositoryPath: repositoryPath))
    }
    
    var body: some View {
        VStack {
            Picker("Refs", selection: $selectedSegment) {
                Text("Branches (\(viewModel.branches.count))").tag(0)
                Text("Tags (\(viewModel.tags.count))").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            List {
                if selectedSegment == 0 {
                    ForEach(viewModel.branches) { branch in
                        RefRowView(ref: branch, repositoryPath: repositoryPath)
                    }
                } else {
                    ForEach(viewModel.tags) { tag in
                        RefRowView(ref: tag, repositoryPath: repositoryPath)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadRefs()
        }
        .task {
            await viewModel.loadRefs()
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

struct RefRowView: View {
    let ref: Ref
    let repositoryPath: String
    
    var body: some View {
        NavigationLink(destination: CommitDetailView(
            repositoryPath: repositoryPath,
            commitSHA: ref.commitSHA
        )) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: ref.type == .branch ? "arrow.triangle.branch" : "tag")
                        .foregroundColor(ref.type == .branch ? .green : .blue)
                    
                    Text(ref.name)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                
                if let message = ref.commitMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if let authorName = ref.authorName {
                        Label(authorName, systemImage: "person.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let date = ref.date {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct RefsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RefsView(repositoryPath: "tosa/reference_model.git")
        }
    }
}
