import Foundation
import SwiftSoup

public struct ProjectInfo {
    public let name: String
    public let path: String
    public let description: String?
    public let lastActivity: Date?
    public let category: String?
    
    public init(name: String, path: String, description: String?, lastActivity: Date?, category: String?) {
        self.name = name
        self.path = path
        self.description = description
        self.lastActivity = lastActivity
        self.category = category
    }
}

public class CatalogueParser: BaseParser, HTMLParserProtocol {
    public typealias Output = [ProjectInfo]
    
    public init() {
        super.init(parserName: "CatalogueParser")
    }
    
    public func parse(html: String) throws -> [ProjectInfo] {
        let doc = try parseDocument(html)
        
        // Look for table with class containing 'list'
        let tables = try doc.select("table").array()
        guard let table = tables.first(where: { element in
            (try? element.className().contains("list")) ?? false
        }) else {
            throw ParserError.missingElement(selector: "table with class 'list'")
        }
        
        let rows = try table.select("tr").array()
        var projects: [ProjectInfo] = []
        
        var currentCategory: String?
        
        for row in rows {
            // Skip header row
            if try row.hasClass("nohover") && row.select("th").count > 0 {
                continue
            }
            
            // Check for category row
            if try row.hasClass("nohover-highlight") {
                if let categoryCell = try row.select("td.reposection").first() {
                    currentCategory = try categoryCell.text()
                }
                continue
            }
            
            // Try to find repository cells (both toplevel and sublevel)
            let nameCell = try row.select("td.sublevel-repo, td.toplevel-repo").first()
            
            guard let cell = nameCell else {
                continue
            }
            
            let link = try cell.select("a").first()
            guard let href = try link?.attr("href") else {
                continue
            }
            
            let name = try link?.text() ?? ""
            let path = href.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            
            // Description is in the second td
            let descriptionCell = try row.select("td").array()
            let description = descriptionCell.count > 1 ? try descriptionCell[1].text() : nil
            
            // Clean up description - remove "[no description]" placeholder
            let cleanDescription = description?.replacingOccurrences(of: "[no description]", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let finalDescription = cleanDescription?.isEmpty == false ? cleanDescription : nil
            
            // Age/activity is in the third td
            let ageText = descriptionCell.count > 2 ? try descriptionCell[2].text() : nil
            let lastActivity = ageText.flatMap { parseDate(from: $0) }
            
            let project = ProjectInfo(
                name: name,
                path: path,
                description: finalDescription,
                lastActivity: lastActivity,
                category: currentCategory
            )
            
            projects.append(project)
        }
        
        return projects
    }
}
