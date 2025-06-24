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
            return "Invalid HTML content"
        case .missingElement(let selector):
            return "Missing required element: \(selector)"
        case .parsingFailed(let reason):
            return "Parsing failed: \(reason)"
        }
    }
}

public class BaseParser {
    public init() {}
    
    func parseDocument(_ html: String) throws -> Document {
        do {
            return try SwiftSoup.parse(html)
        } catch {
            print("BaseParser error: Failed to parse HTML - \(error)")
            throw ParserError.parsingFailed(reason: error.localizedDescription)
        }
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
