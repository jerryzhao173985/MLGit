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
    
    public init() {
        super.init(parserName: "AboutParser")
    }
    
    public func parse(html: String) throws -> AboutContent {
        let doc = try parseDocument(html)
        
        // Debug: Log what we're looking for
        print("AboutParser: Parsing HTML for README content")
        
        // Try multiple selectors for README content
        let selectors = [
            "div#cgit div.content",  // cgit content wrapper
            "div.markdown-body",     // GitHub-style markdown
            "div.readme",            // Generic readme
            "div.about",             // About content
            "div.content",           // Generic content
            "pre",                   // Plain text README
        ]
        
        for selector in selectors {
            if let element = try doc.select(selector).first() {
                print("AboutParser: Found content with selector: \(selector)")
                let innerHtml = try element.html()
                
                // Check if it's actually empty or just says "No README"
                if innerHtml.contains("No README") || innerHtml.contains("doesn't have a README") {
                    print("AboutParser: Found 'No README' message")
                    // Return empty content to trigger the no README state
                    return AboutContent(htmlContent: "")
                }
                
                let cleanedContent = cleanupHTML(innerHtml)
                return AboutContent(htmlContent: cleanedContent)
            }
        }
        
        // If we can't find any README content, check if there's an error message
        if html.contains("No README") || html.contains("doesn't have a README") {
            print("AboutParser: Page indicates no README exists")
            return AboutContent(htmlContent: "")
        }
        
        print("AboutParser: No README content found in any known selector")
        // Return empty content instead of throwing error
        return AboutContent(htmlContent: "")
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