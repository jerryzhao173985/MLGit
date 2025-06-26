import SwiftUI

/// Safe file detail view that won't crash with large files
struct SafeFileDetailView: View {
    let repositoryPath: String
    let filePath: String
    
    @StateObject private var viewModel: FileDetailViewModel
    @State private var fontSize: CGFloat = 14
    
    init(repositoryPath: String, filePath: String) {
        self.repositoryPath = repositoryPath
        self.filePath = filePath
        self._viewModel = StateObject(wrappedValue: FileDetailViewModel(
            repositoryPath: repositoryPath,
            filePath: filePath
        ))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading file...")
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Error Loading File",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            } else if let content = viewModel.fileContent {
                if content.isBinary {
                    BinaryFileDisplay(size: content.size)
                } else if content.content.isEmpty {
                    ContentUnavailableView(
                        "Empty File",
                        systemImage: "doc",
                        description: Text("This file has no content")
                    )
                } else {
                    SafeContentView(
                        content: content.content,
                        fontSize: fontSize
                    )
                }
            } else {
                ContentUnavailableView(
                    "No Content",
                    systemImage: "doc.questionmark",
                    description: Text("Unable to display file content")
                )
            }
        }
        .navigationTitle(URL(string: filePath)?.lastPathComponent ?? filePath)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { fontSize = max(10, fontSize - 2) }) {
                        Label("Decrease Font Size", systemImage: "textformat.size.smaller")
                    }
                    Button(action: { fontSize = min(24, fontSize + 2) }) {
                        Label("Increase Font Size", systemImage: "textformat.size.larger")
                    }
                } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .task {
            await viewModel.loadFile()
        }
    }
}

struct SafeContentView: View {
    let content: String
    let fontSize: CGFloat
    let maxLines = 500 // Limit to prevent crashes
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Show stats
                HStack {
                    Label("\(content.count) characters", systemImage: "doc.text")
                    Spacer()
                    Label("\(lineCount) lines", systemImage: "list.number")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                
                if lineCount > maxLines {
                    Text("Showing first \(maxLines) lines of \(lineCount) total")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal)
                }
                
                // Use a single Text view instead of ForEach for performance
                Text(displayContent)
                    .font(.system(size: fontSize, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical)
        }
    }
    
    private var lines: [String] {
        content.components(separatedBy: .newlines)
    }
    
    private var lineCount: Int {
        lines.count
    }
    
    private var displayContent: String {
        if lineCount > maxLines {
            // Take first maxLines lines
            return lines.prefix(maxLines).joined(separator: "\n")
        }
        return content
    }
}

struct BinaryFileDisplay: View {
    let size: Int64
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Binary File")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(formatBytes(size))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}