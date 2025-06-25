import Foundation
import SwiftSoup

public struct AboutContent {
    public let htmlContent: String
    public let rawMarkdown: String?
    
    public init(htmlContent: String, rawMarkdown: String? = nil) {
        self.htmlContent = htmlContent
        self.rawMarkdown = rawMarkdown
    }
}

public class AboutParser: BaseParser, HTMLParserProtocol {
    public typealias Output = AboutContent
    
    public override init() {
        super.init()
    }
    
    public func parse(html: String) throws -> AboutContent {
        let doc = try parseDocument(html)
        
        // Look for the markdown-body div which contains the rendered README
        guard let markdownDiv = try doc.select("div.markdown-body").first() else {
            // If no markdown content, check if there's any content div
            if let contentDiv = try doc.select("div.content").first() {
                let innerHtml = try contentDiv.html()
                return AboutContent(htmlContent: innerHtml)
            }
            throw ParserError.missingElement(selector: "div.markdown-body or div.content")
        }
        
        // Get the inner HTML content
        let htmlContent = try markdownDiv.html()
        
        // Clean up the HTML content
        let cleanedContent = cleanupHTML(htmlContent)
        
        return AboutContent(htmlContent: cleanedContent)
    }
    
    private func cleanupHTML(_ html: String) -> String {
        // Remove any script tags or potentially unsafe content
        var cleaned = html
        
        // Remove script tags
        cleaned = cleaned.replacingOccurrences(
            of: #"<script[^>]*>[\s\S]*?</script>"#,
            with: "",
            options: .regularExpression
        )
        
        // Remove style tags that might interfere
        cleaned = cleaned.replacingOccurrences(
            of: #"<style[^>]*>[\s\S]*?</style>"#,
            with: "",
            options: .regularExpression
        )
        
        // Fix relative URLs to be absolute
        cleaned = cleaned.replacingOccurrences(
            of: #"href=["'](/[^"']*)"#,
            with: "href=\"https://git.mlplatform.org$1\"",
            options: .regularExpression
        )
        
        // Fix anchor links to work in the app context
        cleaned = cleaned.replacingOccurrences(
            of: #"href=["']#([^"']*)"#,
            with: "href=\"#$1\"",
            options: .regularExpression
        )
        
        return cleaned
    }
}