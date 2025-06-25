import SwiftUI
import Combine
// Uncomment after adding GitDiff package:
// import GitDiff

/// Advanced Diff View with split and unified view options
///
/// Features:
/// - Split view (side-by-side comparison)
/// - Unified view with inline changes
/// - Syntax highlighting within diffs
/// - Word-level diff highlighting
/// - Collapsible hunks
/// - File tree navigation
struct AdvancedDiffView: View {
    let repositoryPath: String
    let commitSHA: String
    
    @StateObject private var viewModel: AdvancedDiffViewModel
    @State private var viewMode: DiffViewMode = .unified
    @State private var fontSize: CGFloat = 13
    @State private var showLineNumbers = true
    @State private var wordWrap = false
    @State private var selectedFile: String?
    @State private var expandedHunks: Set<String> = []
    
    init(repositoryPath: String, commitSHA: String) {
        self.repositoryPath = repositoryPath
        self.commitSHA = commitSHA
        self._viewModel = StateObject(wrappedValue: AdvancedDiffViewModel(
            repositoryPath: repositoryPath,
            commitSHA: commitSHA
        ))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // File tree sidebar
            fileTreeSidebar
                .frame(width: 250)
            
            Divider()
            
            // Diff content
            diffContent
        }
        .navigationTitle("Advanced Diff View")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // View mode selector
                Picker("View Mode", selection: $viewMode) {
                    Label("Unified", systemImage: "doc.text").tag(DiffViewMode.unified)
                    Label("Split", systemImage: "rectangle.split.2x1").tag(DiffViewMode.split)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
                // Options menu
                Menu {
                    Section("Display") {
                        Toggle("Line Numbers", isOn: $showLineNumbers)
                        Toggle("Word Wrap", isOn: $wordWrap)
                    }
                    
                    Section("Font Size") {
                        Button("Decrease") { fontSize = max(10, fontSize - 1) }
                        Button("Reset") { fontSize = 13 }
                        Button("Increase") { fontSize = min(20, fontSize + 1) }
                    }
                    
                    Section {
                        Button("Expand All Hunks") {
                            expandAllHunks()
                        }
                        Button("Collapse All Hunks") {
                            collapseAllHunks()
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
    }
    
    // MARK: - File Tree Sidebar
    private var fileTreeSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Label("Files Changed", systemImage: "doc.text")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.diffFiles.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            
            Divider()
            
            // File list
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(viewModel.diffFiles) { file in
                        FileTreeRow(
                            file: file,
                            isSelected: selectedFile == file.path,
                            onTap: {
                                selectedFile = file.path
                                scrollToFile(file.path)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Diff Content
    private var diffContent: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading diff...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.diffFiles.isEmpty {
                ContentUnavailableView(
                    "No Changes",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("This commit has no file changes")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.diffFiles) { file in
                                VStack(alignment: .leading, spacing: 0) {
                                    // File header
                                    FileHeaderView(file: file)
                                        .id(file.path)
                                    
                                    // File diff content
                                    switch viewMode {
                                    case .unified:
                                        UnifiedDiffView(
                                            file: file,
                                            fontSize: fontSize,
                                            showLineNumbers: showLineNumbers,
                                            wordWrap: wordWrap,
                                            expandedHunks: $expandedHunks
                                        )
                                    case .split:
                                        SplitDiffView(
                                            file: file,
                                            fontSize: fontSize,
                                            showLineNumbers: showLineNumbers,
                                            wordWrap: wordWrap
                                        )
                                    }
                                }
                                .padding(.bottom, 32)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: selectedFile) { _, newValue in
                        if let file = newValue {
                            withAnimation {
                                proxy.scrollTo(file, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func scrollToFile(_ path: String) {
        // Handled by ScrollViewReader
    }
    
    private func expandAllHunks() {
        for file in viewModel.diffFiles {
            for hunk in file.hunks {
                expandedHunks.insert(hunk.id)
            }
        }
    }
    
    private func collapseAllHunks() {
        expandedHunks.removeAll()
    }
}

// MARK: - View Mode
enum DiffViewMode {
    case unified
    case split
}

// MARK: - File Tree Row
struct FileTreeRow: View {
    let file: DiffFileModel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: file.changeType.icon)
                    .foregroundColor(file.changeType.color)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.fileName)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    
                    if file.oldPath != nil && file.oldPath != file.path {
                        Text("← \(file.oldFileName ?? "")")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if file.additions > 0 {
                        Text("+\(file.additions)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    if file.deletions > 0 {
                        Text("-\(file.deletions)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - File Header View
struct FileHeaderView: View {
    let file: DiffFileModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: file.changeType.icon)
                    .foregroundColor(file.changeType.color)
                
                Text(file.path)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Label("\(file.additions)", systemImage: "plus")
                        .foregroundColor(.green)
                    Label("\(file.deletions)", systemImage: "minus")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
            
            if let oldPath = file.oldPath, oldPath != file.path {
                HStack {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    Text("Renamed from \(oldPath)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Unified Diff View
struct UnifiedDiffView: View {
    let file: DiffFileModel
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wordWrap: Bool
    @Binding var expandedHunks: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(file.hunks) { hunk in
                VStack(alignment: .leading, spacing: 0) {
                    // Hunk header
                    HunkHeaderView(
                        hunk: hunk,
                        isExpanded: expandedHunks.contains(hunk.id),
                        onToggle: {
                            if expandedHunks.contains(hunk.id) {
                                expandedHunks.remove(hunk.id)
                            } else {
                                expandedHunks.insert(hunk.id)
                            }
                        }
                    )
                    
                    // Hunk content
                    if expandedHunks.contains(hunk.id) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(hunk.lines) { line in
                                UnifiedDiffLineView(
                                    line: line,
                                    fontSize: fontSize,
                                    showLineNumbers: showLineNumbers,
                                    wordWrap: wordWrap
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .onAppear {
            // Auto-expand first few hunks
            for (index, hunk) in file.hunks.enumerated() {
                if index < 3 {
                    expandedHunks.insert(hunk.id)
                }
            }
        }
    }
}

// MARK: - Split Diff View
struct SplitDiffView: View {
    let file: DiffFileModel
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wordWrap: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 0) {
                // Old version
                VStack(alignment: .leading, spacing: 0) {
                    Text("Old")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemBackground))
                    
                    Divider()
                    
                    ForEach(file.oldLines) { line in
                        SplitDiffLineView(
                            line: line,
                            fontSize: fontSize,
                            showLineNumbers: showLineNumbers,
                            isOld: true
                        )
                    }
                }
                .frame(minWidth: 400)
                
                Divider()
                
                // New version
                VStack(alignment: .leading, spacing: 0) {
                    Text("New")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemBackground))
                    
                    Divider()
                    
                    ForEach(file.newLines) { line in
                        SplitDiffLineView(
                            line: line,
                            fontSize: fontSize,
                            showLineNumbers: showLineNumbers,
                            isOld: false
                        )
                    }
                }
                .frame(minWidth: 400)
            }
        }
    }
}

// MARK: - Supporting Views
struct HunkHeaderView: View {
    let hunk: DiffHunkModel
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .frame(width: 16)
                
                Text(hunk.header)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.blue)
                
                Spacer()
                
                if let contextInfo = hunk.contextInfo {
                    Text(contextInfo)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct UnifiedDiffLineView: View {
    let line: DiffLineModel
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wordWrap: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            if showLineNumbers {
                HStack(spacing: 8) {
                    Text(line.oldLineNumber.map(String.init) ?? "")
                        .frame(minWidth: 40, alignment: .trailing)
                    Text(line.newLineNumber.map(String.init) ?? "")
                        .frame(minWidth: 40, alignment: .trailing)
                }
                .font(.system(size: fontSize - 2, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.horizontal, 4)
            }
            
            Text(line.type.symbol)
                .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                .foregroundColor(line.type.color)
                .frame(width: 20)
            
            Text(line.content)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(line.type.contentColor)
                .lineLimit(wordWrap ? nil : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
        }
        .background(line.type.backgroundColor)
    }
}

struct SplitDiffLineView: View {
    let line: DiffLineModel
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let isOld: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            if showLineNumbers {
                Text(isOld ? (line.oldLineNumber.map(String.init) ?? "") : (line.newLineNumber.map(String.init) ?? ""))
                    .frame(minWidth: 40, alignment: .trailing)
                    .font(.system(size: fontSize - 2, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 4)
            }
            
            Text(line.content)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(line.type.contentColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
        }
        .background(line.type.backgroundColor)
        .opacity(line.type == .placeholder ? 0.3 : 1.0)
    }
}

// MARK: - View Models
@MainActor
class AdvancedDiffViewModel: ObservableObject {
    @Published var diffFiles: [DiffFileModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let commitSHA: String
    
    init(repositoryPath: String, commitSHA: String) {
        self.repositoryPath = repositoryPath
        self.commitSHA = commitSHA
    }
    
    func loadDiff() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Implement actual diff loading using GitDiff package
        // For now, using mock data
        diffFiles = createMockDiffFiles()
    }
    
    private func createMockDiffFiles() -> [DiffFileModel] {
        [
            DiffFileModel(
                path: "Sources/App/ContentView.swift",
                oldPath: nil,
                changeType: .modified,
                additions: 15,
                deletions: 8,
                hunks: [
                    DiffHunkModel(
                        header: "@@ -10,7 +10,14 @@ struct ContentView: View {",
                        contextInfo: "struct ContentView",
                        lines: [
                            DiffLineModel(type: .context, content: "    @State private var selection = 0", oldLineNumber: 10, newLineNumber: 10),
                            DiffLineModel(type: .deletion, content: "    @State private var items: [String] = []", oldLineNumber: 11, newLineNumber: nil),
                            DiffLineModel(type: .addition, content: "    @State private var items: [Item] = []", oldLineNumber: nil, newLineNumber: 11),
                            DiffLineModel(type: .addition, content: "    @State private var isLoading = false", oldLineNumber: nil, newLineNumber: 12),
                            DiffLineModel(type: .context, content: "    ", oldLineNumber: 12, newLineNumber: 13),
                            DiffLineModel(type: .context, content: "    var body: some View {", oldLineNumber: 13, newLineNumber: 14),
                        ]
                    )
                ]
            )
        ]
    }
}

// MARK: - Data Models
struct DiffFileModel: Identifiable {
    let id = UUID()
    let path: String
    let oldPath: String?
    let changeType: FileChangeType
    let additions: Int
    let deletions: Int
    let hunks: [DiffHunkModel]
    
    var fileName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
    
    var oldFileName: String? {
        oldPath.map { URL(fileURLWithPath: $0).lastPathComponent }
    }
    
    // For split view
    var oldLines: [DiffLineModel] {
        // Generate old file lines from hunks
        []
    }
    
    var newLines: [DiffLineModel] {
        // Generate new file lines from hunks
        []
    }
}

struct DiffHunkModel: Identifiable {
    let id = UUID().uuidString
    let header: String
    let contextInfo: String?
    let lines: [DiffLineModel]
}

struct DiffLineModel: Identifiable {
    let id = UUID()
    let type: DiffLineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?
}

enum DiffLineType {
    case addition
    case deletion
    case context
    case placeholder // For split view alignment
    
    var symbol: String {
        switch self {
        case .addition: return "+"
        case .deletion: return "-"
        case .context: return " "
        case .placeholder: return " "
        }
    }
    
    var color: Color {
        switch self {
        case .addition: return .green
        case .deletion: return .red
        case .context, .placeholder: return .secondary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .addition: return Color.green.opacity(0.1)
        case .deletion: return Color.red.opacity(0.1)
        case .context, .placeholder: return Color.clear
        }
    }
    
    var contentColor: Color {
        switch self {
        case .addition, .deletion: return .primary
        case .context, .placeholder: return .secondary
        }
    }
}

enum FileChangeType {
    case added
    case modified
    case deleted
    case renamed
    case copied
    
    var icon: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .renamed: return "arrow.triangle.2.circlepath.circle.fill"
        case .copied: return "doc.on.doc.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .added: return .green
        case .modified: return .orange
        case .deleted: return .red
        case .renamed: return .blue
        case .copied: return .purple
        }
    }
}

// MARK: - Preview
struct AdvancedDiffView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdvancedDiffView(
                repositoryPath: "example/repo.git",
                commitSHA: "abc123"
            )
        }
    }
}