import SwiftUI
import Highlightr
import Combine

struct ChunkedCodeView: View {
    @ObservedObject var chunkManager: FileContentChunkManager
    let language: String
    let fontSize: CGFloat
    let theme: String
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    let highlightr: Highlightr?
    
    @State private var visibleChunks: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Progress indicator
            if chunkManager.progress < 1.0 {
                ProgressHeader(
                    progress: chunkManager.progress,
                    progressText: chunkManager.progressText
                )
            }
            
            // Content
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                        ForEach(Array(chunkManager.chunks.enumerated()), id: \.element.id) { index, chunk in
                            ChunkView(
                                chunk: chunk,
                                index: index,
                                language: language,
                                fontSize: fontSize,
                                theme: theme,
                                showLineNumbers: showLineNumbers,
                                wrapLines: wrapLines,
                                searchText: searchText,
                                highlightr: highlightr,
                                totalLines: chunkManager.totalLines
                            )
                            .onAppear {
                                loadNearbyChunks(around: index)
                            }
                            .id(chunk.id)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func loadNearbyChunks(around index: Int) {
        // Load current chunk and adjacent chunks
        let start = max(0, index - 1)
        let end = min(chunkManager.chunks.count, index + 2)
        
        Task {
            await chunkManager.loadChunksInRange(start..<end)
        }
    }
}

// MARK: - Progress Header

struct ProgressHeader: View {
    let progress: Double
    let progressText: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(progressText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .tint(.accentColor)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Chunk View

struct ChunkView: View {
    let chunk: FileContentChunk
    let index: Int
    let language: String
    let fontSize: CGFloat
    let theme: String
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    let highlightr: Highlightr?
    let totalLines: Int
    
    @State private var highlightedLines: [NSAttributedString] = []
    
    var body: some View {
        Group {
            if chunk.isLoaded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(chunk.lines.enumerated()), id: \.offset) { lineIndex, line in
                        LineView(
                            line: line,
                            lineNumber: chunk.startLine + lineIndex + 1,
                            highlightedLine: lineIndex < highlightedLines.count ? highlightedLines[lineIndex] : nil,
                            fontSize: fontSize,
                            showLineNumbers: showLineNumbers,
                            wrapLines: wrapLines,
                            searchText: searchText,
                            maxLineNumberWidth: String(totalLines).count
                        )
                    }
                }
                .onAppear {
                    if highlightedLines.isEmpty {
                        applyHighlighting()
                    }
                }
                .onChange(of: theme) { _, _ in
                    applyHighlighting()
                }
            } else {
                // Placeholder for unloaded chunk
                ChunkPlaceholder(
                    startLine: chunk.startLine + 1,
                    endLine: chunk.endLine + 1,
                    fontSize: fontSize
                )
            }
        }
    }
    
    private func applyHighlighting() {
        guard let highlightr = highlightr else {
            highlightedLines = []
            return
        }
        
        highlightr.setTheme(to: theme)
        
        highlightedLines = chunk.lines.map { line in
            highlightr.highlight(line, as: language, fastRender: true) ?? NSAttributedString(string: line)
        }
    }
}

// MARK: - Line View

struct LineView: View {
    let line: String
    let lineNumber: Int
    let highlightedLine: NSAttributedString?
    let fontSize: CGFloat
    let showLineNumbers: Bool
    let wrapLines: Bool
    let searchText: String
    let maxLineNumberWidth: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if showLineNumbers {
                Text(String(format: "%\(maxLineNumberWidth)d", lineNumber))
                    .font(.system(size: fontSize - 2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 12)
            }
            
            if let highlightedLine = highlightedLine {
                HighlightedLineText(
                    attributedString: highlightedLine,
                    fontSize: fontSize,
                    wrapLines: wrapLines,
                    searchText: searchText
                )
            } else {
                Text(line.isEmpty ? " " : line)
                    .font(.system(size: fontSize, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(wrapLines ? nil : 1)
            }
        }
    }
}

// MARK: - Highlighted Line Text

struct HighlightedLineText: UIViewRepresentable {
    let attributedString: NSAttributedString
    let fontSize: CGFloat
    let wrapLines: Bool
    let searchText: String
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        return label
    }
    
    func updateUIView(_ label: UILabel, context: Context) {
        // Apply search highlighting if needed
        if !searchText.isEmpty {
            let highlighted = highlightSearchMatches(in: attributedString, searchText: searchText)
            label.attributedText = highlighted
        } else {
            label.attributedText = attributedString
        }
        
        label.numberOfLines = wrapLines ? 0 : 1
        label.lineBreakMode = wrapLines ? .byWordWrapping : .byClipping
    }
    
    private func highlightSearchMatches(in attributedString: NSAttributedString, searchText: String) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: attributedString)
        let text = attributedString.string
        
        let searchOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        var searchRange = text.startIndex..<text.endIndex
        
        while let range = text.range(of: searchText, options: searchOptions, range: searchRange) {
            let nsRange = NSRange(range, in: text)
            result.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.5), range: nsRange)
            searchRange = range.upperBound..<text.endIndex
        }
        
        return result
    }
}

// MARK: - Chunk Placeholder

struct ChunkPlaceholder: View {
    let startLine: Int
    let endLine: Int
    let fontSize: CGFloat
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lines \(startLine) - \(endLine)")
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(.secondary)
                
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.3))
        .cornerRadius(8)
    }
}