import Foundation
import SwiftUI

struct CodeView: View {
    let repositoryPath: String
    @StateObject private var viewModel: CodeViewModel
    @State private var currentPath: [String] = []
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self._viewModel = StateObject(wrappedValue: CodeViewModel(repositoryPath: repositoryPath))
    }
    
    var body: some View {
        List {
            if !currentPath.isEmpty {
                Button(action: navigateUp) {
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.blue)
                        Text("..")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
            }
            
            ForEach(viewModel.files) { file in
                if file.isDirectory {
                    Button(action: { navigateToDirectory(file) }) {
                        FileRowView(file: file)
                    }
                    .foregroundColor(.primary)
                } else {
                    NavigationLink(destination: FileDetailView(
                        repositoryPath: repositoryPath,
                        filePath: file.path
                    )) {
                        FileRowView(file: file)
                    }
                }
            }
        }
        .navigationTitle(currentPath.last ?? "Code")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadFiles(path: currentPath.joined(separator: "/"))
        }
        .task {
            await viewModel.loadFiles(path: currentPath.joined(separator: "/"))
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    private func navigateToDirectory(_ file: FileNode) {
        currentPath.append(file.name)
        Task {
            await viewModel.loadFiles(path: currentPath.joined(separator: "/"))
        }
    }
    
    private func navigateUp() {
        if !currentPath.isEmpty {
            currentPath.removeLast()
            Task {
                await viewModel.loadFiles(path: currentPath.joined(separator: "/"))
            }
        }
    }
}

struct FileRowView: View {
    let file: FileNode
    
    var body: some View {
        HStack {
            Image(systemName: file.icon)
                .foregroundColor(file.isDirectory ? .blue : .secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(.body, design: .monospaced))
                
                if let size = file.size, !file.isDirectory {
                    Text(formatBytes(size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if file.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct CodeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CodeView(repositoryPath: "tosa/reference_model.git")
        }
    }
}
