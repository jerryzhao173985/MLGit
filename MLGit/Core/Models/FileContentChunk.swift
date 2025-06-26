import Foundation
import Combine

/// Model for chunk-based file loading
struct FileContentChunk: Identifiable {
    let id = UUID()
    let startLine: Int
    let endLine: Int
    let lines: [String]
    let isLoaded: Bool
    
    var lineCount: Int {
        lines.count
    }
    
    static func placeholder(startLine: Int, endLine: Int) -> FileContentChunk {
        FileContentChunk(
            startLine: startLine,
            endLine: endLine,
            lines: [],
            isLoaded: false
        )
    }
}

/// Manager for chunk-based file loading
@MainActor
class FileContentChunkManager: ObservableObject {
    @Published var chunks: [FileContentChunk] = []
    @Published var totalLines: Int = 0
    @Published var loadedLines: Int = 0
    @Published var isLoading: Bool = false
    
    let chunkSize: Int
    private let content: String
    private var lineOffsets: [Int] = []  // Store byte offsets instead of all lines
    private var cachedChunks: [Int: [String]] = [:]  // Cache loaded chunks
    private let maxCachedChunks = 10  // Limit memory usage
    
    init(content: String, chunkSize: Int = 500) {
        self.content = content
        self.chunkSize = chunkSize
        
        // Calculate line offsets without storing all lines
        calculateLineOffsets()
        self.totalLines = lineOffsets.count - 1
        
        // Initialize with placeholder chunks
        initializePlaceholders()
        
        // Load first chunk immediately
        Task {
            await loadInitialChunks()
        }
    }
    
    private func calculateLineOffsets() {
        lineOffsets = [0]  // First line starts at offset 0
        
        var offset = 0
        for char in content {
            offset += 1
            if char == "\n" {
                lineOffsets.append(offset)
            }
        }
        
        // Add final offset if content doesn't end with newline
        if offset > 0 && (lineOffsets.last ?? 0) < content.count {
            lineOffsets.append(content.count)
        }
    }
    
    private func initializePlaceholders() {
        chunks = []
        var currentLine = 0
        
        while currentLine < totalLines {
            let endLine = min(currentLine + chunkSize - 1, totalLines - 1)
            chunks.append(.placeholder(startLine: currentLine, endLine: endLine))
            currentLine = endLine + 1
        }
    }
    
    private func loadInitialChunks() async {
        // Load first 2 chunks immediately for better UX
        for i in 0..<min(2, chunks.count) {
            await loadChunk(at: i)
        }
    }
    
    func loadChunk(at index: Int) async {
        guard index < chunks.count,
              !chunks[index].isLoaded else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let chunk = chunks[index]
        let startLine = chunk.startLine
        let endLine = chunk.endLine
        
        // Check cache first
        var chunkLines: [String]
        if let cached = cachedChunks[index] {
            chunkLines = cached
        } else {
            // Extract lines for this chunk using offsets
            chunkLines = extractLines(from: startLine, to: endLine)
            
            // Cache the chunk
            cachedChunks[index] = chunkLines
            
            // Evict old chunks if cache is too large
            if cachedChunks.count > maxCachedChunks {
                evictOldestChunks()
            }
        }
        
        // Replace placeholder with loaded chunk
        chunks[index] = FileContentChunk(
            startLine: startLine,
            endLine: endLine,
            lines: chunkLines,
            isLoaded: true
        )
        
        // Update loaded lines count
        loadedLines = chunks.filter { $0.isLoaded }.reduce(0) { $0 + $1.lineCount }
    }
    
    private func extractLines(from startLine: Int, to endLine: Int) -> [String] {
        guard startLine < lineOffsets.count - 1 else { return [] }
        
        let adjustedEndLine = min(endLine, lineOffsets.count - 2)
        var lines: [String] = []
        
        for lineIndex in startLine...adjustedEndLine {
            let startOffset = lineOffsets[lineIndex]
            let endOffset = lineOffsets[lineIndex + 1]
            
            let startIdx = content.index(content.startIndex, offsetBy: startOffset)
            let endIdx = content.index(content.startIndex, offsetBy: endOffset)
            
            var line = String(content[startIdx..<endIdx])
            // Remove trailing newline if present
            if line.hasSuffix("\n") {
                line.removeLast()
            }
            lines.append(line)
        }
        
        return lines
    }
    
    private func evictOldestChunks() {
        // Keep only the most recently loaded chunks
        let loadedChunkIndices = chunks.enumerated()
            .filter { $0.element.isLoaded }
            .map { $0.offset }
            .sorted()
        
        if loadedChunkIndices.count > maxCachedChunks {
            let indicesToEvict = loadedChunkIndices.prefix(loadedChunkIndices.count - maxCachedChunks)
            for index in indicesToEvict {
                cachedChunks.removeValue(forKey: index)
                // Mark chunk as unloaded to free memory
                if index < chunks.count {
                    let chunk = chunks[index]
                    chunks[index] = FileContentChunk.placeholder(
                        startLine: chunk.startLine,
                        endLine: chunk.endLine
                    )
                }
            }
        }
    }
    
    func loadChunksInRange(_ range: Range<Int>) async {
        for index in range {
            if index < chunks.count && !chunks[index].isLoaded {
                await loadChunk(at: index)
            }
        }
    }
    
    var progress: Double {
        guard totalLines > 0 else { return 1.0 }
        return Double(loadedLines) / Double(totalLines)
    }
    
    var progressText: String {
        "\(loadedLines) / \(totalLines) lines loaded"
    }
}