import SwiftUI

/// Debug view for testing file loading issues
struct DebugFileView: View {
    let repositoryPath: String
    let filePath: String
    
    @StateObject private var viewModel: FileDetailViewModel
    @State private var debugInfo: String = ""
    @State private var isDebugEnabled = false
    
    init(repositoryPath: String, filePath: String) {
        self.repositoryPath = repositoryPath
        self.filePath = filePath
        self._viewModel = StateObject(wrappedValue: FileDetailViewModel(
            repositoryPath: repositoryPath,
            filePath: filePath
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Debug controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Debug Information")
                        .font(.headline)
                    
                    Toggle("Enable HTML Debug Logging", isOn: $isDebugEnabled)
                        .onChange(of: isDebugEnabled) { _, newValue in
                            HTMLDebugLogger.shared.setEnabled(newValue)
                        }
                    
                    if isDebugEnabled {
                        Text("Logs saved to: \(HTMLDebugLogger.shared.debugDirectoryPath)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Repository:")
                        Text(repositoryPath)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("File Path:")
                        Text(filePath)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // URLs being used
                VStack(alignment: .leading, spacing: 12) {
                    Text("URLs")
                        .font(.headline)
                    
                    Group {
                        Label("Plain URL", systemImage: "link")
                        Text(URLBuilder.plain(repositoryPath: repositoryPath, path: filePath).absoluteString)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                        
                        Label("Blob URL", systemImage: "link")
                        Text(URLBuilder.blob(repositoryPath: repositoryPath, path: filePath).absoluteString)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(.headline)
                    
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading...")
                        }
                    } else if let error = viewModel.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Error", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if let content = viewModel.fileContent {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Success", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Group {
                                Text("Size: \(formatBytes(content.size))")
                                Text("Is Binary: \(content.isBinary ? "Yes" : "No")")
                                Text("Content Length: \(content.content.count) characters")
                                Text("Line Count: \(content.content.components(separatedBy: .newlines).count)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    } else {
                        Label("No content loaded", systemImage: "doc.questionmark")
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // File content preview
                if let content = viewModel.fileContent, !content.isBinary {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content Preview")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: true) {
                            Text(String(content.content.prefix(1000)))
                                .font(.system(size: 12, design: .monospaced))
                                .padding()
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(8)
                        }
                        
                        if content.content.count > 1000 {
                            Text("Showing first 1000 characters of \(content.content.count) total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: { Task { await loadFile() } }) {
                        Label("Reload File", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if isDebugEnabled {
                        Button(action: clearDebugLogs) {
                            Label("Clear Debug Logs", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                    NavigationLink(destination: FileDetailView(
                        repositoryPath: repositoryPath,
                        filePath: filePath
                    )) {
                        Label("View in Normal Mode", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Debug File View")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFile()
        }
    }
    
    private func loadFile() async {
        debugInfo = "Starting file load...\n"
        await viewModel.loadFile()
        
        if let error = viewModel.error {
            debugInfo += "Error: \(error)\n"
        } else if let content = viewModel.fileContent {
            debugInfo += "Success! Loaded \(content.content.count) characters\n"
        } else {
            debugInfo += "No error but no content either\n"
        }
    }
    
    private func clearDebugLogs() {
        Task {
            await HTMLDebugLogger.shared.clearLogs()
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// Preview
struct DebugFileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DebugFileView(
                repositoryPath: "test/repo.git",
                filePath: "README.md"
            )
        }
    }
}