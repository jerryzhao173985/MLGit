import SwiftUI
import Highlightr

struct EnhancedDiffView: View {
    let repositoryPath: String
    let commitSHA: String
    @StateObject private var viewModel: DiffViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fontSize: CGFloat = 13
    @State private var showLineNumbers = true
    @State private var splitView = false
    
    init(repositoryPath: String, commitSHA: String) {
        self.repositoryPath = repositoryPath
        self.commitSHA = commitSHA
        self._viewModel = StateObject(wrappedValue: DiffViewModel(
            repositoryPath: repositoryPath,
            commitSHA: commitSHA
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading diff...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let patch = viewModel.rawPatch {
                    GitPatchView(
                        patch: patch,
                        fontSize: fontSize,
                        showLineNumbers: showLineNumbers,
                        splitView: splitView
                    )
                } else {
                    ContentUnavailableView(
                        "No Changes",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("This commit has no file changes")
                    )
                }
            }
            .navigationTitle("Diff View")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Display") {
                            Toggle("Line Numbers", isOn: $showLineNumbers)
                            Toggle("Split View", isOn: $splitView)
                        }
                        
                        Section("Font Size") {
                            Button(action: { fontSize = max(10, fontSize - 1) }) {
                                Label("Decrease", systemImage: "minus.magnifyingglass")
                            }
                            Button(action: { fontSize = min(20, fontSize + 1) }) {
                                Label("Increase", systemImage: "plus.magnifyingglass")
                            }
                        }
                        
                        if let patch = viewModel.rawPatch {
                            Section {
                                ShareLink(item: patch) {
                                    Label("Share Diff", systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
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

// MARK: - Git Patch View

struct GitPatchView: View {
    let patch: String
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let splitView: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let patchData = parsePatch(patch)
                
                // Header information
                if let header = patchData.header {
                    PatchHeaderView(header: header)
                        .padding()
                }
                
                // File changes
                ForEach(patchData.files) { file in
                    FileDiffView(
                        file: file,
                        fontSize: fontSize,
                        showLineNumbers: showLineNumbers,
                        splitView: splitView
                    )
                }
            }
        }
    }
    
    private func parsePatch(_ patch: String) -> PatchData {
        let lines = patch.components(separatedBy: .newlines)
        var header: PatchHeader?
        var files: [FileDiff] = []
        var currentFile: FileDiff?
        var currentHunk: DiffHunk?
        
        var i = 0
        while i < lines.count {
            let line = lines[i]
            
            // Parse header
            if line.hasPrefix("From ") {
                var headerLines: [String] = []
                while i < lines.count && !lines[i].hasPrefix("diff --git") {
                    headerLines.append(lines[i])
                    i += 1
                }
                header = parsePatchHeader(headerLines)
                continue
            }
            
            // Parse file diff
            if line.hasPrefix("diff --git") {
                // Save previous file
                if let file = currentFile {
                    files.append(file)
                }
                
                // Start new file
                let filePath = extractFilePath(from: line)
                currentFile = FileDiff(path: filePath)
                currentHunk = nil
            }
            
            // Parse file stats
            else if line.hasPrefix("---") || line.hasPrefix("+++") {
                // Skip for now
            }
            
            // Parse hunk header
            else if line.hasPrefix("@@") {
                if let hunk = parseHunkHeader(line) {
                    currentHunk = hunk
                    currentFile?.hunks.append(hunk)
                }
            }
            
            // Parse diff lines
            else if let hunk = currentHunk {
                if line.hasPrefix("+") && !line.hasPrefix("+++") {
                    hunk.lines.append(DiffLine(type: .addition, content: String(line.dropFirst())))
                } else if line.hasPrefix("-") && !line.hasPrefix("---") {
                    hunk.lines.append(DiffLine(type: .deletion, content: String(line.dropFirst())))
                } else if line.hasPrefix(" ") {
                    hunk.lines.append(DiffLine(type: .context, content: String(line.dropFirst())))
                } else if line.hasPrefix("\\") {
                    hunk.lines.append(DiffLine(type: .noNewline, content: line))
                }
            }
            
            i += 1
        }
        
        // Save last file
        if let file = currentFile {
            files.append(file)
        }
        
        return PatchData(header: header, files: files)
    }
    
    private func parsePatchHeader(_ lines: [String]) -> PatchHeader {
        var header = PatchHeader()
        
        for line in lines {
            if line.hasPrefix("From ") {
                header.commitHash = String(line.dropFirst(5).prefix(40))
            } else if line.hasPrefix("From: ") {
                header.author = String(line.dropFirst(6))
            } else if line.hasPrefix("Date: ") {
                header.date = String(line.dropFirst(6))
            } else if line.hasPrefix("Subject: ") {
                header.subject = String(line.dropFirst(9))
            } else if line.contains("changed") && line.contains("insertion") {
                header.stats = line
            }
        }
        
        return header
    }
    
    private func extractFilePath(from line: String) -> String {
        // Extract from "diff --git a/path/to/file b/path/to/file"
        let components = line.split(separator: " ")
        if components.count >= 4 {
            let path = String(components[2].dropFirst(2)) // Remove "a/"
            return path
        }
        return "unknown"
    }
    
    private func parseHunkHeader(_ line: String) -> DiffHunk? {
        // Parse "@@ -1,4 +1,6 @@ function name"
        let pattern = #"@@ -(\d+),?(\d+)? \+(\d+),?(\d+)? @@(.*)?"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        let hunk = DiffHunk()
        hunk.header = line
        
        if let range = Range(match.range(at: 5), in: line) {
            hunk.functionContext = String(line[range]).trimmingCharacters(in: .whitespaces)
        }
        
        return hunk
    }
}

// MARK: - Patch Header View

struct PatchHeaderView: View {
    let header: PatchHeader
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let hash = header.commitHash {
                HStack {
                    Text("Commit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(hash.prefix(12)))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
            
            if let author = header.author {
                HStack {
                    Text("Author")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(author)
                        .font(.body)
                }
            }
            
            if let date = header.date {
                HStack {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(date)
                        .font(.body)
                }
            }
            
            if let subject = header.subject {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subject")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(subject)
                        .font(.headline)
                }
            }
            
            if let stats = header.stats {
                Text(stats)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - File Diff View

struct FileDiffView: View {
    let file: FileDiff
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let splitView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                Text(file.path)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                Spacer()
                Text("\(file.additions) additions, \(file.deletions) deletions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            
            // Hunks
            ForEach(file.hunks) { hunk in
                HunkView(
                    hunk: hunk,
                    fontSize: fontSize,
                    showLineNumbers: showLineNumbers
                )
            }
        }
        .padding(.bottom)
    }
}

// MARK: - Hunk View

struct HunkView: View {
    let hunk: DiffHunk
    let fontSize: CGFloat
    let showLineNumbers: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hunk header
            HStack {
                Text(hunk.header)
                    .font(.system(size: fontSize - 1, weight: .medium, design: .monospaced))
                    .foregroundColor(.blue)
                if let context = hunk.functionContext, !context.isEmpty {
                    Text(context)
                        .font(.system(size: fontSize - 1, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            
            // Diff lines
            ForEach(Array(hunk.lines.enumerated()), id: \.offset) { index, line in
                EnhancedDiffLineView(
                    line: line,
                    lineNumber: index + 1,
                    fontSize: fontSize,
                    showLineNumbers: showLineNumbers
                )
            }
        }
    }
}

// MARK: - Diff Line View

struct EnhancedDiffLineView: View {
    let line: DiffLine
    let lineNumber: Int
    let fontSize: CGFloat
    let showLineNumbers: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            if showLineNumbers {
                Text("\(lineNumber)")
                    .font(.system(size: fontSize - 2, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(minWidth: 40, alignment: .trailing)
                    .padding(.trailing, 8)
            }
            
            Text(line.indicator)
                .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                .foregroundColor(line.indicatorColor)
                .frame(width: 20)
            
            Text(line.content.isEmpty ? " " : line.content)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(line.contentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
        }
        .background(line.backgroundColor)
    }
}

// MARK: - Data Models

struct PatchData {
    var header: PatchHeader?
    var files: [FileDiff]
}

struct PatchHeader {
    var commitHash: String?
    var author: String?
    var date: String?
    var subject: String?
    var stats: String?
}

class FileDiff: Identifiable {
    let id = UUID()
    let path: String
    var hunks: [DiffHunk] = []
    
    var additions: Int {
        hunks.reduce(0) { sum, hunk in
            sum + hunk.lines.filter { $0.type == .addition }.count
        }
    }
    
    var deletions: Int {
        hunks.reduce(0) { sum, hunk in
            sum + hunk.lines.filter { $0.type == .deletion }.count
        }
    }
    
    init(path: String) {
        self.path = path
    }
}

class DiffHunk: Identifiable {
    let id = UUID()
    var header: String = ""
    var functionContext: String?
    var lines: [DiffLine] = []
}

class DiffLine: Identifiable {
    let id = UUID()
    let type: LineType
    let content: String
    
    enum LineType {
        case addition
        case deletion
        case context
        case noNewline
    }
    
    init(type: LineType, content: String) {
        self.type = type
        self.content = content
    }
    
    var indicator: String {
        switch type {
        case .addition: return "+"
        case .deletion: return "-"
        case .context: return " "
        case .noNewline: return "\\"
        }
    }
    
    var indicatorColor: Color {
        switch type {
        case .addition: return .green
        case .deletion: return .red
        case .context, .noNewline: return .secondary
        }
    }
    
    var contentColor: Color {
        switch type {
        case .addition, .deletion: return .primary
        case .context, .noNewline: return .secondary
        }
    }
    
    var backgroundColor: Color {
        switch type {
        case .addition: return .green.opacity(0.15)
        case .deletion: return .red.opacity(0.15)
        case .context, .noNewline: return .clear
        }
    }
}