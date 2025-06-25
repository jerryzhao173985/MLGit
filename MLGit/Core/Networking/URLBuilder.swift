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
        let urlString = "\(baseURL)/\(repositoryPath)/patch/?id=\(sha)"
        print("URLBuilder: Constructing patch URL: \(urlString)")
        return URL(string: urlString)!
    }
    
    static func tree(repositoryPath: String, path: String? = nil, sha: String? = nil) -> URL {
        var urlString = "\(baseURL)/\(repositoryPath)/tree/"
        var queryItems: [String] = []
        
        if let path = path {
            let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
            queryItems.append("path=\(encodedPath)")
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
        // URL encode the path to handle special characters and nested paths
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        var urlString = "\(baseURL)/\(repositoryPath)/blob/?path=\(encodedPath)"
        
        if let sha = sha {
            urlString += "&id=\(sha)"
        }
        
        return URL(string: urlString)!
    }
    
    static func plain(repositoryPath: String, path: String, sha: String? = nil) -> URL {
        // URL encode the path to handle special characters and nested paths
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        var urlString = "\(baseURL)/\(repositoryPath)/plain/\(encodedPath)"
        
        if let sha = sha {
            urlString += "?id=\(sha)"
        }
        
        return URL(string: urlString)!
    }
    
    static func diff(repositoryPath: String, sha: String) -> URL {
        let urlString = "\(baseURL)/\(repositoryPath)/diff/?id=\(sha)"
        print("URLBuilder: Constructing diff URL: \(urlString)")
        return URL(string: urlString)!
    }
    
    static func summary(repositoryPath: String) -> URL {
        URL(string: "\(baseURL)/\(repositoryPath)/")!
    }
}