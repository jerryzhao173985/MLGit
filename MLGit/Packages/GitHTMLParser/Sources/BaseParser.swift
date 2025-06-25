import Foundation
import SwiftSoup

public protocol HTMLParserProtocol {
    associatedtype Output
    func parse(html: String) throws -> Output
}

public enum ParserError: LocalizedError {
    case invalidHTML
    case missingElement(selector: String)
    case parsingFailed(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidHTML:
            return "Invalid or empty response from git server. The page may have failed to load."
        case .missingElement(let selector):
            if selector.contains("blob") {
                return "File content not found. The file may be empty or the server response was incomplete."
            } else if selector.contains("diff") {
                return "Diff data not found. The commit may have no changes or the diff is still loading."
            } else if selector.contains("list") {
                return "Repository list not found. The server may be updating or temporarily unavailable."
            } else {
                return "Required content not found on page. The git server may have returned an incomplete response."
            }
        case .parsingFailed(let reason):
            return "Failed to process git server response: \(reason)"
        }
    }
}

public class BaseParser {
    public let parserName: String
    
    public init(parserName: String = "BaseParser") {
        self.parserName = parserName
    }
    
    func parseDocument(_ html: String, url: URL? = nil) throws -> Document {
        do {
            // Check if HTML is empty or too small
            guard !html.isEmpty else {
                print("\(parserName) error: Empty HTML content")
                throw ParserError.invalidHTML
            }
            
            // Log first 500 characters for debugging
            let preview = String(html.prefix(500))
            print("\(parserName): Parsing HTML preview: \(preview)...")
            
            // Log full HTML if URL is provided and debug mode is enabled
            if let url = url {
                logHTMLForDebug(html, url: url)
            }
            
            return try SwiftSoup.parse(html)
        } catch {
            print("\(parserName) error: Failed to parse HTML - \(error)")
            print("\(parserName) error: HTML length was \(html.count) characters")
            throw ParserError.parsingFailed(reason: error.localizedDescription)
        }
    }
    
    // Default implementation - can be overridden by subclasses
    func parseDocument(_ html: String) throws -> Document {
        try parseDocument(html, url: nil)
    }
    
    private func logHTMLForDebug(_ html: String, url: URL) {
        // This would integrate with HTMLDebugLogger if available
        // For now, just log a message
        print("\(parserName): Processing HTML from \(url.absoluteString)")
    }
    
    func parseDate(from string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try ISO8601DateFormatter first
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }
        // Try custom DateFormatters
        let shortFormatter = DateFormatter.cgitShortFormat
        if let date = shortFormatter.date(from: trimmed) {
            return date
        }
        let longFormatter = DateFormatter.cgitLongFormat
        if let date = longFormatter.date(from: trimmed) {
            return date
        }
        
        if let relativeDate = parseRelativeDate(from: trimmed) {
            return relativeDate
        }
        
        return nil
    }
    
    private func parseRelativeDate(from string: String) -> Date? {
        let cleaned = string.replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let components = cleaned.split(separator: " ")
        guard components.count >= 2,
              let value = Int(components[0]) else { return nil }
        
        let unit = String(components[1]).lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        switch unit {
        case "second", "seconds", "sec", "secs":
            return calendar.date(byAdding: .second, value: -value, to: now)
        case "minute", "minutes", "min", "mins":
            return calendar.date(byAdding: .minute, value: -value, to: now)
        case "hour", "hours":
            return calendar.date(byAdding: .hour, value: -value, to: now)
        case "day", "days":
            return calendar.date(byAdding: .day, value: -value, to: now)
        case "week", "weeks":
            return calendar.date(byAdding: .weekOfYear, value: -value, to: now)
        case "month", "months":
            return calendar.date(byAdding: .month, value: -value, to: now)
        case "year", "years":
            return calendar.date(byAdding: .year, value: -value, to: now)
        default:
            return nil
        }
    }
}

extension DateFormatter {
    static let cgitShortFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
    
    static let cgitLongFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
