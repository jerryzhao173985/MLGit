import SwiftUI

struct OptimizedFileDetailView: View {
    let repositoryPath: String
    let filePath: String
    
    @StateObject private var viewModel: FileDetailViewModel
    @State private var chunkManager: FileContentChunkManager?
    @State private var fontSize: CGFloat = 14
    @State private var theme = "github"
    @State private var showLineNumbers = true
    @State private var wrapLines = false
    @State private var searchText = ""
    @State private var showSearch = false
    
    // Removed Highlightr - now using Runestone
    
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
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    Task { await viewModel.loadFile() }
                }
            } else if let content = viewModel.fileContent {
                // Check if we have actual content to display
                if content.content.isEmpty && !content.isBinary && content.size > 0 {
                    // File has content but encoding failed
                    EncodingIssueView(
                        fileContent: content,
                        fontSize: fontSize
                    )
                } else {
                    let _ = print("OptimizedFileDetailView: Displaying content - fileType: \(fileType), isBinary: \(content.isBinary), contentLength: \(content.content.count)")
                    
                    FileContentView(
                        content: content,
                        fileType: fileType,
                        fontSize: fontSize,
                        theme: theme,
                        showLineNumbers: showLineNumbers,
                        wrapLines: wrapLines,
                        searchText: searchText,
                        chunkManager: chunkManager
                    )
                    .onAppear {
                        if chunkManager == nil && !content.isBinary {
                            // Initialize chunk manager for large files
                            if content.content.count > 10000 { // ~10KB threshold (lowered for better performance)
                                chunkManager = FileContentChunkManager(content: content.content, chunkSize: 300)
                            }
                        }
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
        .navigationTitle(fileName)
        .navigationBarTitleDisplayMode(.inline)
        .swipeToGoBack()
        .searchable(text: $searchText, isPresented: $showSearch)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if let content = viewModel.fileContent, !content.isBinary {
                    toolbarMenu
                }
            }
        }
        .task {
            await viewModel.loadFile()
        }
    }
    
    private var fileName: String {
        URL(string: filePath)?.lastPathComponent ?? filePath
    }
    
    private var fileType: FileType {
        FileTypeDetector.detectType(from: filePath, content: viewModel.fileContent?.content)
    }
    
    @ViewBuilder
    private var toolbarMenu: some View {
        Menu {
            // Theme selection for code files
            if case .code = fileType {
                Section("Theme") {
                    Button("GitHub") { theme = "github" }
                    Button("Xcode") { theme = "xcode" }
                    Button("VS Code Dark") { theme = "vs2015" }
                    Button("Atom One Dark") { theme = "atom-one-dark" }
                    Button("Monokai") { theme = "monokai-sublime" }
                    Button("Tomorrow Night") { theme = "tomorrow-night" }
                    Button("Dracula") { theme = "dracula" }
                }
            }
            
            Section("Display") {
                Toggle("Line Numbers", isOn: $showLineNumbers)
                Toggle("Wrap Lines", isOn: $wrapLines)
                Button(action: { showSearch.toggle() }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
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
                if let content = viewModel.fileContent {
                    ShareLink(item: content.content) {
                        Label("Share File", systemImage: "square.and.arrow.up")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

// MARK: - Content View

struct FileContentView: View {
    let content: FileContent
    let fileType: FileType
    let fontSize: CGFloat
    let theme: String
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    let chunkManager: FileContentChunkManager?
    
    var body: some View {
        let _ = print("FileContentView: Rendering fileType: \(fileType), contentLength: \(content.content.count)")
        
        switch fileType {
        case .binary:
            BinaryFileDisplay(size: content.size)
            
        case .markdown:
            OptimizedMarkdownView(
                content: content.content,
                fontSize: fontSize
            )
            
        case .image:
            ImageFileView(
                content: content,
                filePath: content.path
            )
            
        case .json:
            JSONFileView(
                content: content.content,
                fontSize: fontSize
            )
            
        case .code(let language):
            let _ = print("FileContentView: Rendering code file with language: \(language)")
            // Use SmartCodeView which handles both Runestone and fallback
            SmartCodeView(
                content: content.content,
                language: language,
                fontSize: fontSize,
                theme: theme,
                showLineNumbers: showLineNumbers,
                wrapLines: wrapLines,
                searchText: searchText
            )
            
        default:
            // Plain text
            let _ = print("FileContentView: Falling back to PlainTextView")
            PlainTextView(
                content: content.content,
                fontSize: fontSize,
                showLineNumbers: showLineNumbers,
                wrapLines: wrapLines,
                searchText: searchText
            )
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading file...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("Error Loading File", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Encoding Issue View

struct EncodingIssueView: View {
    let fileContent: FileContent
    let fontSize: CGFloat
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Encoding Issue")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("This file contains characters that couldn't be displayed with standard text encoding.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("File Size:")
                        .fontWeight(.medium)
                    Text("\(fileContent.size) bytes")
                        .foregroundColor(.secondary)
                }
                .font(.callout)
                
                HStack {
                    Text("Encoding Attempted:")
                        .fontWeight(.medium)
                    Text(fileContent.encoding)
                        .foregroundColor(.secondary)
                }
                .font(.callout)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            Text("The file may be using a non-standard character encoding or may be a binary file incorrectly identified as text.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}