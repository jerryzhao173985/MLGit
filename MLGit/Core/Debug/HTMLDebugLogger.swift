import Foundation

/// A debug logger for capturing and saving HTML responses for parser debugging
@MainActor
class HTMLDebugLogger {
    static let shared = HTMLDebugLogger()
    
    private let debugDirectory: URL
    private var isEnabled: Bool = false
    private let dateFormatter: DateFormatter
    
    private init() {
        // Create debug directory in Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        debugDirectory = documentsPath.appendingPathComponent("MLGitDebug")
        
        // Setup date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: debugDirectory, withIntermediateDirectories: true)
        
        // Check if debug mode is enabled via UserDefaults
        isEnabled = UserDefaults.standard.bool(forKey: "MLGitDebugMode")
    }
    
    /// Enable or disable debug logging
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "MLGitDebugMode")
        
        if enabled {
            print("HTMLDebugLogger: Enabled - logs will be saved to \(debugDirectory.path)")
        } else {
            print("HTMLDebugLogger: Disabled")
        }
    }
    
    /// Log HTML response for a specific URL and parser type
    func logHTML(_ html: String, for url: URL, parserType: String) {
        guard isEnabled else { return }
        
        Task {
            await saveHTML(html, for: url, parserType: parserType)
        }
    }
    
    private func saveHTML(_ html: String, for url: URL, parserType: String) async {
        let timestamp = dateFormatter.string(from: Date())
        let urlPath = url.path.replacingOccurrences(of: "/", with: "_")
        let filename = "\(timestamp)_\(parserType)_\(urlPath).html"
        let fileURL = debugDirectory.appendingPathComponent(filename)
        
        do {
            // Create metadata header
            let metadata = """
            <!-- MLGit Debug Log
            URL: \(url.absoluteString)
            Parser: \(parserType)
            Date: \(Date())
            HTML Length: \(html.count) characters
            -->
            
            """
            
            let fullContent = metadata + html
            try fullContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            print("HTMLDebugLogger: Saved \(parserType) HTML to \(filename)")
            
            // Also save a summary of the HTML structure
            await saveSummary(for: html, url: url, parserType: parserType, timestamp: timestamp)
        } catch {
            print("HTMLDebugLogger: Failed to save HTML - \(error)")
        }
    }
    
    private func saveSummary(for html: String, url: URL, parserType: String, timestamp: String) async {
        let summaryFilename = "\(timestamp)_\(parserType)_summary.txt"
        let summaryURL = debugDirectory.appendingPathComponent(summaryFilename)
        
        var summary = """
        HTML Structure Summary
        =====================
        URL: \(url.absoluteString)
        Parser: \(parserType)
        Date: \(Date())
        HTML Length: \(html.count) characters
        
        Key Elements Found:
        
        """
        
        // Check for common cgit elements
        let elements = [
            ("table.list", "Project list table"),
            ("table.blob", "File content table"),
            ("table.diff", "Diff table"),
            ("table.log", "Commit log table"),
            ("div.path", "Breadcrumb navigation"),
            ("div.content", "Main content div"),
            ("div.blob", "File blob div"),
            ("td.lines", "File content lines"),
            ("td.linenumbers", "Line numbers"),
            ("pre", "Preformatted text blocks"),
            ("div.bin-blob", "Binary file notice")
        ]
        
        for (selector, description) in elements {
            let count = html.components(separatedBy: selector).count - 1
            if count > 0 {
                summary += "✓ \(selector) - \(description) (found \(count) times)\n"
            }
        }
        
        // Check for file paths in common locations
        summary += "\nPotential file paths found:\n"
        let pathPatterns = [
            "href=\"/[^\"]+/blob/",
            "href=\"/[^\"]+/tree/",
            "href=\"/[^\"]+/plain/"
        ]
        
        for pattern in pathPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) {
                let matchedString = String(html[Range(match.range, in: html)!])
                summary += "- \(matchedString)\n"
            }
        }
        
        try? summary.write(to: summaryURL, atomically: true, encoding: .utf8)
    }
    
    /// Get the debug directory path for user reference
    var debugDirectoryPath: String {
        debugDirectory.path
    }
    
    /// Clear all debug logs
    func clearLogs() async {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: debugDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for fileURL in contents {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        print("HTMLDebugLogger: Cleared all debug logs")
    }
    
    /// Get list of saved debug files
    func getSavedLogs() -> [URL] {
        let contents = try? FileManager.default.contentsOfDirectory(
            at: debugDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        
        return contents?.sorted { url1, url2 in
            let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            return date1! > date2!
        } ?? []
    }
}