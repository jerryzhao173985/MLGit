import SwiftUI

/// Ultra-simple file view to test if content loads without crashes
struct SimpleFileView: View {
    let repositoryPath: String
    let filePath: String
    
    @State private var content: String = ""
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Status header
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                    } else if error != nil {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("Error")
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text("Loaded \(content.count) characters")
                            .foregroundColor(.green)
                    }
                }
                .font(.caption)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if !content.isEmpty {
                    // Show first 1000 characters to avoid memory issues
                    let preview = String(content.prefix(1000))
                    
                    VStack(alignment: .leading) {
                        Text("Preview (first 1000 chars):")
                            .font(.caption.bold())
                        
                        Text(preview)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        
                        if content.count > 1000 {
                            Text("... and \(content.count - 1000) more characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(filePath.components(separatedBy: "/").last ?? filePath)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFile()
        }
    }
    
    func loadFile() async {
        print("SimpleFileView: Loading \(filePath)")
        isLoading = true
        error = nil
        
        do {
            let fileContent = try await GitService.shared.fetchFileContent(
                repositoryPath: repositoryPath,
                path: filePath,
                sha: nil
            )
            
            await MainActor.run {
                self.content = fileContent.content
                self.isLoading = false
                print("SimpleFileView: Successfully loaded \(fileContent.content.count) characters")
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
                print("SimpleFileView: Error - \(error)")
            }
        }
    }
}