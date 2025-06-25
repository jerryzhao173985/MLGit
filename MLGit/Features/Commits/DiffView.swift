import Foundation
import SwiftUI

struct DiffView: View {
    let repositoryPath: String
    let commitSHA: String
    @StateObject private var viewModel: DiffViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fontSize: CGFloat = 12
    @State private var showContext = true
    @State private var contextLines = 3
    
    init(repositoryPath: String, commitSHA: String) {
        self.repositoryPath = repositoryPath
        self.commitSHA = commitSHA
        self._viewModel = StateObject(wrappedValue: DiffViewModel(
            repositoryPath: repositoryPath,
            commitSHA: commitSHA
        ))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading diff...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let diffFiles = viewModel.diffFiles, !diffFiles.isEmpty {
                List {
                    ForEach(diffFiles) { file in
                        Section {
                            DiffFileView(
                                file: file,
                                fontSize: fontSize,
                                showContext: showContext,
                                contextLines: contextLines
                            )
                        } header: {
                            DiffFileHeaderView(file: file)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            } else if let patch = viewModel.rawPatch {
                // Fallback to raw patch view
                ScrollView([.horizontal, .vertical]) {
                    PatchContentView(patch: patch, fontSize: fontSize)
                        .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Changes",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("This commit has no file changes")
                )
            }
        }
        .navigationTitle("Diff")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Section("Font Size") {
                        Button(action: { fontSize = max(10, fontSize - 2) }) {
                            Label("Decrease", systemImage: "textformat.size.smaller")
                        }
                        Button(action: { fontSize = min(24, fontSize + 2) }) {
                            Label("Increase", systemImage: "textformat.size.larger")
                        }
                    }
                    
                    Section("Context") {
                        Toggle("Show Context", isOn: $showContext)
                        
                        if showContext {
                            Picker("Context Lines", selection: $contextLines) {
                                Text("1 line").tag(1)
                                Text("3 lines").tag(3)
                                Text("5 lines").tag(5)
                                Text("10 lines").tag(10)
                            }
                        }
                    }
                    
                    Divider()
                    
                    if let patch = viewModel.rawPatch {
                        ShareLink(item: patch) {
                            Label("Share Diff", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadDiff()
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

struct DiffFileHeaderView: View {
    let file: LegacyDiffFile
    
    var body: some View {
        HStack {
            Image(systemName: fileIcon)
                .foregroundColor(fileColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.path)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                
                if let oldPath = file.oldPath, oldPath != file.path {
                    HStack(spacing: 4) {
                        Text("from")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(oldPath)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
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

struct DiffFileView: View {
    let file: LegacyDiffFile
    let fontSize: CGFloat
    let showContext: Bool
    let contextLines: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(file.hunks) { hunk in
                    DiffHunkView(
                        hunk: hunk,
                        fontSize: fontSize,
                        showContext: showContext,
                        contextLines: contextLines
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DiffHunkView: View {
    let hunk: LegacyDiffHunk
    let fontSize: CGFloat
    let showContext: Bool
    let contextLines: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hunk header
            Text(hunk.header)
                .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Hunk lines
            ForEach(filteredLines) { line in
                DiffLineView(line: line, fontSize: fontSize)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var filteredLines: [LegacyDiffLine] {
        if !showContext {
            return hunk.lines.filter { $0.type != .context }
        }
        
        var result: [LegacyDiffLine] = []
        var contextBuffer: [LegacyDiffLine] = []
        var lastNonContextIndex = -1
        
        for (index, line) in hunk.lines.enumerated() {
            if line.type != .context {
                // Add limited context before this change
                if !contextBuffer.isEmpty {
                    let startIndex = max(0, contextBuffer.count - contextLines)
                    result.append(contentsOf: contextBuffer[startIndex...])
                    contextBuffer.removeAll()
                }
                
                result.append(line)
                lastNonContextIndex = result.count - 1
            } else {
                contextBuffer.append(line)
                
                // If we have enough context after a change, add it and clear
                if lastNonContextIndex >= 0 && contextBuffer.count >= contextLines {
                    result.append(contentsOf: contextBuffer.prefix(contextLines))
                    contextBuffer.removeAll()
                    lastNonContextIndex = -1
                }
            }
        }
        
        // Add remaining context if within limit
        if lastNonContextIndex >= 0 && !contextBuffer.isEmpty {
            result.append(contentsOf: contextBuffer.prefix(contextLines))
        }
        
        return result
    }
}

struct DiffLineView: View {
    let line: LegacyDiffLine
    let fontSize: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            // Line numbers
            HStack(spacing: 0) {
                Text(lineNumber(line.oldLineNumber))
                    .font(.system(size: fontSize * 0.9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                    .padding(.trailing, 4)
                
                Text(lineNumber(line.newLineNumber))
                    .font(.system(size: fontSize * 0.9, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 50, alignment: .trailing)
                    .padding(.trailing, 8)
            }
            .background(Color.secondary.opacity(0.05))
            
            // Type indicator
            Text(line.type.indicator)
                .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                .foregroundColor(line.type.color)
                .frame(width: 20)
            
            // Line content
            Text(line.content)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(line.type.contentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 20)
        }
        .background(line.type.backgroundColor)
    }
    
    private func lineNumber(_ number: Int?) -> String {
        guard let number = number else { return "" }
        return String(number)
    }
}

// Supporting Models moved to LegacyDiffTypes.swift
// Use EnhancedDiffView for new features with better visualization

struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DiffView(
                repositoryPath: "tosa/reference_model.git",
                commitSHA: "cd167baf693b155805622e340008388cc89f61b2"
            )
        }
    }
}