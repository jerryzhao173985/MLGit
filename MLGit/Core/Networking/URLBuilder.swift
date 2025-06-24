import Foundation

struct URLBuilder {
    static let baseURL = "https://git.mlplatform.org"
    
    static func catalogue() -> URL {
        URL(string: baseURL)!
    }
    
    static func repository(path: String) -> URL {
        URL(string: "\(baseURL)/\(path)")!
    }
    
    static func about(repositoryPath: String) -> URL {
        URL(string: "\(baseURL)/\(repositoryPath)/about/")!
    }
    
    static func refs(repositoryPath: String) -> URL {
        URL(string: "\(baseURL)/\(repositoryPath)/refs/")!
    }
    
    static func log(repositoryPath: String, offset: Int = 0) -> URL {
        if offset > 0 {
            return URL(string: "\(baseURL)/\(repositoryPath)/log/?ofs=\(offset)")!
        }
        return URL(string: "\(baseURL)/\(repositoryPath)/log/")!
    }
    
    static func commit(repositoryPath: String, sha: String) -> URL {
        URL(string: "\(baseURL)/\(repositoryPath)/commit/?id=\(sha)")!
    }
    
    static func patch(repositoryPath: String, sha: String) -> URL {
        URL(string: "\(baseURL)/\(repositoryPath)/patch/?id=\(sha)")!
    }
    
    static func tree(repositoryPath: String, path: String? = nil, sha: String? = nil) -> URL {
        var urlString = "\(baseURL)/\(repositoryPath)/tree/"
        var queryItems: [String] = []
        
        if let path = path {
            queryItems.append("path=\(path)")
        }
        
        if let sha = sha {
            queryItems.append("id=\(sha)")
        }
        
        if !queryItems.isEmpty {
            urlString += "?" + queryItems.joined(separator: "&")
        }
        
        return URL(string: urlString)!
    }
    
    static func blob(repositoryPath: String, path: String, sha: String? = nil) -> URL {
        var urlString = "\(baseURL)/\(repositoryPath)/blob/?path=\(path)"
        
        if let sha = sha {
            urlString += "&id=\(sha)"
        }
        
        return URL(string: urlString)!
    }
    
    static func plain(repositoryPath: String, path: String, sha: String? = nil) -> URL {
        var urlString = "\(baseURL)/\(repositoryPath)/plain/\(path)"
        
        if let sha = sha {
            urlString += "?id=\(sha)"
        }
        
        return URL(string: urlString)!
    }
    
    static func diff(repositoryPath: String, sha: String) -> URL {
        URL(string: "\(baseURL)/\(repositoryPath)/diff/?id=\(sha)")!
    }
    
    static func summary(repositoryPath: String) -> URL {
        URL(string: "\(baseURL)/\(repositoryPath)/")!
    }
}