import Foundation
import SwiftUI

struct FileDetailView: View {
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Unable to Load File",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let content = viewModel.fileContent {
                if content.isBinary {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Binary File")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(formatBytes(content.size))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if content.content.isEmpty {
                    ContentUnavailableView(
                        "Empty File",
                        systemImage: "doc",
                        description: Text("This file has no content")
                    )
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        FileCodeView(content: content.content, fontSize: fontSize)
                            .padding()
                    }
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
                    Divider()
                    if let content = viewModel.fileContent {
                        ShareLink(item: content.content) {
                            Label("Share File", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadFile()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct FileCodeView: View {
    let content: String
    let fontSize: CGFloat
    
    var body: some View {
        let lines = content.components(separatedBy: .newlines)
        let lineNumberWidth = String(lines.count).count * 10 + 20
        
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                    Text("\(index + 1)")
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: CGFloat(lineNumberWidth), alignment: .trailing)
                        .padding(.trailing, 8)
                }
            }
            
            Divider()
                .padding(.horizontal, 8)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line.isEmpty ? " " : line)
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
        }
    }
}

struct FileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FileDetailView(
                repositoryPath: "tosa/reference_model.git",
                filePath: "README.md"
            )
        }
    }
}
