import Foundation
import SwiftUI

struct PatchView: View {
    let repositoryPath: String
    let commitSHA: String
    @StateObject private var viewModel: PatchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fontSize: CGFloat = 12
    
    init(repositoryPath: String, commitSHA: String) {
        self.repositoryPath = repositoryPath
        self.commitSHA = commitSHA
        self._viewModel = StateObject(wrappedValue: PatchViewModel(
            repositoryPath: repositoryPath,
            commitSHA: commitSHA
        ))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading patch...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let patch = viewModel.patch {
                ScrollView([.horizontal, .vertical]) {
                    PatchContentView(patch: patch, fontSize: fontSize)
                        .padding()
                }
            }
        }
        .navigationTitle("Patch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { fontSize = max(10, fontSize - 2) }) {
                        Label("Decrease Font Size", systemImage: "textformat.size.smaller")
                    }
                    Button(action: { fontSize = min(24, fontSize + 2) }) {
                        Label("Increase Font Size", systemImage: "textformat.size.larger")
                    }
                    Divider()
                    if let patch = viewModel.patch {
                        ShareLink(item: patch) {
                            Label("Share Patch", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadPatch()
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

struct PatchContentView: View {
    let patch: String
    let fontSize: CGFloat
    
    var body: some View {
        let lines = patch.components(separatedBy: .newlines)
        
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack {
                    Text(line.isEmpty ? " " : line)
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .foregroundColor(lineColor(for: line))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                .background(lineBackground(for: line))
            }
        }
    }
    
    private func lineColor(for line: String) -> Color {
        if line.hasPrefix("+") && !line.hasPrefix("+++") {
            return .green
        } else if line.hasPrefix("-") && !line.hasPrefix("---") {
            return .red
        } else if line.hasPrefix("@@") {
            return .blue
        } else if line.hasPrefix("diff ") || line.hasPrefix("index ") {
            return .purple
        } else {
            return .primary
        }
    }
    
    private func lineBackground(for line: String) -> Color {
        if line.hasPrefix("+") && !line.hasPrefix("+++") {
            return .green.opacity(0.1)
        } else if line.hasPrefix("-") && !line.hasPrefix("---") {
            return .red.opacity(0.1)
        } else if line.hasPrefix("@@") {
            return .blue.opacity(0.1)
        } else {
            return .clear
        }
    }
}

struct PatchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatchView(
                repositoryPath: "tosa/reference_model.git",
                commitSHA: "cd167baf693b155805622e340008388cc89f61b2"
            )
        }
    }
}
