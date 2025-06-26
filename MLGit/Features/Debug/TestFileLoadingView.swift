import SwiftUI

struct TestFileLoadingView: View {
    @State private var content: String = ""
    @State private var isLoading = true
    @State private var error: String?
    
    let repositoryPath = "tosa/reference_model.git"
    let filePath = "README.md"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Test File Loading")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                VStack(alignment: .leading) {
                    Text("Repository: \(repositoryPath)")
                    Text("File: \(filePath)")
                }
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error: \(error)")
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading) {
                        Text("Content Loaded: \(content.count) characters")
                            .font(.headline)
                        
                        Text(content)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                
                Button("Reload") {
                    Task {
                        await loadFile()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .task {
            await loadFile()
        }
    }
    
    func loadFile() async {
        isLoading = true
        error = nil
        content = ""
        
        do {
            let fileContent = try await GitService.shared.fetchFileContent(
                repositoryPath: repositoryPath,
                path: filePath,
                sha: nil
            )
            
            await MainActor.run {
                self.content = fileContent.content
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}