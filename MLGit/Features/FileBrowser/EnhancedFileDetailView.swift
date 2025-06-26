import SwiftUI
import Highlightr

struct EnhancedFileDetailView: View {
    let repositoryPath: String
    let filePath: String
    @StateObject private var viewModel: FileDetailViewModel
    @State private var fontSize: CGFloat = 14
    @State private var theme = "github"
    @State private var showLineNumbers = true
    @State private var wrapLines = false
    
    // Highlightr instance
    private let highlightr = Highlightr()
    
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
            
            let _ = print("EnhancedFileDetailView: isLoading=\(viewModel.isLoading), hasError=\(viewModel.error != nil), hasContent=\(viewModel.fileContent != nil)")
            
            if viewModel.isLoading {
                ProgressView("Loading file...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error {
                ContentUnavailableView(
                    "Error Loading File",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            } else if let content = viewModel.fileContent {
                let _ = print("EnhancedFileDetailView: Displaying content - isBinary: \(content.isBinary), isMarkdown: \(isMarkdownFile), isImage: \(isImageFile), contentLength: \(content.content.count)")
                
                // Check for empty content
                if content.content.isEmpty && !content.isBinary {
                    if content.size > 0 {
                        // File has content but couldn't be decoded
                        ContentUnavailableView(
                            "Encoding Issue",
                            systemImage: "exclamationmark.triangle",
                            description: Text("Unable to decode file with encoding: \(content.encoding)\nFile size: \(content.size) bytes")
                        )
                    } else {
                        // File is genuinely empty
                        ContentUnavailableView(
                            "Empty File",
                            systemImage: "doc",
                            description: Text("This file contains no content")
                        )
                    }
                } else if content.isBinary {
                    BinaryFileView(fileContent: content)
                } else if isMarkdownFile {
                    MarkdownFileView(content: content.content, fontSize: fontSize)
                } else if isImageFile {
                    // Display image files
                    ImageFileView(
                        content: content,
                        filePath: content.path
                    )
                } else {
                    // Use optimized code view for all code files
                    let detectedLanguage = Self.detectLanguage(from: filePath) ?? "text"
                    let _ = print("EnhancedFileDetailView: Using OptimizedCodeView with language: \(detectedLanguage)")
                    
                    OptimizedCodeView(
                        content: content.content,
                        language: detectedLanguage,
                        fontSize: fontSize,
                        theme: theme,
                        showLineNumbers: showLineNumbers,
                        wrapLines: wrapLines,
                        searchText: "",
                        highlightr: highlightr
                    )
                }
            } else {
                ContentUnavailableView(
                    "No Content",
                    systemImage: "doc.questionmark",
                    description: Text("File content is empty or could not be loaded")
                )
            }
        }
        .navigationTitle(fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if let content = viewModel.fileContent, !content.isBinary {
                    Menu {
                        if !isMarkdownFile {
                            Section("Theme") {
                                Button("GitHub") { theme = "github" }
                                Button("Xcode") { theme = "xcode" }
                                Button("VS Code Dark") { theme = "vs2015" }
                                Button("Atom One Dark") { theme = "atom-one-dark" }
                                Button("Monokai") { theme = "monokai" }
                            }
                        }
                        
                        Section("Display") {
                            Toggle("Line Numbers", isOn: $showLineNumbers)
                            Toggle("Wrap Lines", isOn: $wrapLines)
                        }
                        
                        Section("Font Size") {
                            Button(action: { fontSize = max(10, fontSize - 1) }) {
                                Label("Decrease", systemImage: "minus.magnifyingglass")
                            }
                            Button(action: { fontSize = min(24, fontSize + 1) }) {
                                Label("Increase", systemImage: "plus.magnifyingglass")
                            }
                        }
                        
                        Section {
                            ShareLink(item: content.content) {
                                Label("Share File", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            print("EnhancedFileDetailView: task started for \(filePath)")
            await viewModel.loadFile()
            print("EnhancedFileDetailView: task completed")
        }
        .onChange(of: viewModel.fileContent) { _, newValue in
            print("EnhancedFileDetailView: content changed - hasContent: \(newValue != nil)")
        }
        .onAppear {
            print("EnhancedFileDetailView: appeared for \(filePath)")
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    private var fileName: String {
        URL(string: filePath)?.lastPathComponent ?? filePath
    }
    
    private var isMarkdownFile: Bool {
        let lowercased = fileName.lowercased()
        return lowercased.hasSuffix(".md") || lowercased.hasSuffix(".markdown")
    }
    
    private var isImageFile: Bool {
        let lowercased = fileName.lowercased()
        return lowercased.hasSuffix(".png") || lowercased.hasSuffix(".jpg") || 
               lowercased.hasSuffix(".jpeg") || lowercased.hasSuffix(".gif") || 
               lowercased.hasSuffix(".svg") || lowercased.hasSuffix(".webp")
    }
    
    static func detectLanguage(from path: String) -> String? {
        let filename = (path as NSString).lastPathComponent.lowercased()
        
        // Handle special files without extensions
        switch filename {
        case ".gitignore": return "gitignore"
        case ".gitmodules": return "gitconfig"
        case ".gitconfig": return "gitconfig"
        case ".bashrc", ".bash_profile": return "bash"
        case "dockerfile": return "dockerfile"
        case "makefile", "gnumakefile": return "makefile"
        case "podfile": return "ruby"
        case "gemfile": return "ruby"
        default: break
        }
        
        // Handle file extensions
        let ext = (path as NSString).pathExtension.lowercased()
        
        switch ext {
        case "swift": return "swift"
        case "m", "mm": return "objectivec"
        case "h", "hpp": return "cpp"
        case "c": return "c"
        case "cpp", "cc", "cxx": return "cpp"
        case "js": return "javascript"
        case "ts": return "typescript"
        case "py": return "python"
        case "rb": return "ruby"
        case "java": return "java"
        case "kt", "kts": return "kotlin"
        case "go": return "go"
        case "rs": return "rust"
        case "php": return "php"
        case "sh", "bash": return "bash"
        case "json": return "json"
        case "xml": return "xml"
        case "html", "htm": return "html"
        case "css": return "css"
        case "scss", "sass": return "scss"
        case "sql": return "sql"
        case "yml", "yaml": return "yaml"
        case "toml": return "toml"
        case "md", "markdown": return "markdown"
        default: return nil
        }
    }
}

// MARK: - Code File View

struct CodeFileView: View {
    let content: String
    let filePath: String
    let fontSize: CGFloat
    let theme: String
    let showLineNumbers: Bool
    let wrapLines: Bool
    let highlightr: Highlightr?
    
    @State private var attributedText: NSAttributedString?
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            if let attributedText = attributedText {
                HighlightedCodeView(
                    attributedText: attributedText,
                    fontSize: fontSize,
                    showLineNumbers: showLineNumbers,
                    wrapLines: wrapLines
                )
            } else {
                PlainCodeView(
                    content: content,
                    fontSize: fontSize,
                    showLineNumbers: showLineNumbers,
                    wrapLines: wrapLines
                )
            }
        }
        .onAppear {
            highlightCode()
        }
        .onChange(of: theme) { _, _ in
            highlightCode()
        }
    }
    
    private func highlightCode() {
        guard let highlightr = highlightr else { return }
        
        highlightr.setTheme(to: theme)
        
        // Detect language from file extension
        let language = EnhancedFileDetailView.detectLanguage(from: filePath)
        if let highlighted = highlightr.highlight(content, as: language) {
            attributedText = highlighted
        } else {
            // Fallback to auto-detection
            if let highlighted = highlightr.highlight(content) {
                attributedText = highlighted
            }
        }
    }
}

// MARK: - Highlighted Code View

struct HighlightedCodeView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wrapLines: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if showLineNumbers {
            textView.attributedText = addLineNumbers(to: attributedText)
        } else {
            textView.attributedText = attributedText
        }
        
        // Update font size
        let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableText.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular), range: NSRange(location: 0, length: mutableText.length))
        textView.attributedText = mutableText
        
        // Configure wrapping
        if wrapLines {
            textView.textContainer.lineBreakMode = .byWordWrapping
            textView.textContainer.widthTracksTextView = true
        } else {
            textView.textContainer.lineBreakMode = .byClipping
            textView.textContainer.widthTracksTextView = false
            textView.textContainer.maximumNumberOfLines = 0
        }
    }
    
    private func addLineNumbers(to text: NSAttributedString) -> NSAttributedString {
        let lines = text.string.components(separatedBy: .newlines)
        let result = NSMutableAttributedString()
        
        let lineNumberAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.monospacedSystemFont(ofSize: fontSize - 2, weight: .regular)
        ]
        
        for (index, _) in lines.enumerated() {
            let lineNumber = String(format: "%4d  ", index + 1)
            result.append(NSAttributedString(string: lineNumber, attributes: lineNumberAttributes))
        }
        
        return result
    }
}

// MARK: - Plain Code View

struct PlainCodeView: View {
    let content: String
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wrapLines: Bool
    
    var body: some View {
        let lines = content.components(separatedBy: .newlines)
        
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                HStack(spacing: 0) {
                    if showLineNumbers {
                        Text(String(format: "%4d", index + 1))
                            .font(.system(size: fontSize - 2, weight: .regular, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.trailing, 12)
                    }
                    
                    Text(line.isEmpty ? " " : line)
                        .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(wrapLines ? nil : 1)
                }
            }
        }
        .padding()
    }
}

// MARK: - Binary File View

struct BinaryFileView: View {
    let fileContent: FileContent
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Binary File")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(formatBytes(fileContent.size))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let mimeType = detectMimeType(from: fileContent.path) {
                Text(mimeType)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func detectMimeType(from path: String) -> String? {
        let ext = (path as NSString).pathExtension.lowercased()
        
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "pdf": return "application/pdf"
        case "zip": return "application/zip"
        case "tar", "gz": return "application/gzip"
        case "exe": return "application/x-executable"
        case "dmg": return "application/x-apple-diskimage"
        default: return nil
        }
    }
}

// MARK: - Markdown File View

struct MarkdownFileView: View {
    let content: String
    let fontSize: CGFloat
    
    var body: some View {
        MarkdownView(content: content, fontSize: fontSize)
    }
}