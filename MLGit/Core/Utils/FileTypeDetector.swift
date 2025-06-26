import Foundation

enum FileType {
    case markdown
    case code(language: String)
    case json
    case xml
    case yaml
    case toml
    case ini
    case image(type: String)
    case pdf
    case text
    case binary
    case unknown
}

struct FileTypeDetector {
    static func detectType(from filePath: String, content: String? = nil, data: Data? = nil) -> FileType {
        let fileName = URL(string: filePath)?.lastPathComponent ?? filePath
        let ext = (fileName as NSString).pathExtension.lowercased()
        
        // Check for specific file types first
        switch ext {
        // Markdown
        case "md", "markdown", "mdown", "mkd", "mdx":
            return .markdown
            
        // Images
        case "png", "jpg", "jpeg", "gif", "webp", "svg", "ico":
            return .image(type: ext)
            
        // Data formats
        case "json":
            return .json
        case "xml", "plist":
            return .xml
        case "yml", "yaml":
            return .yaml
        case "toml":
            return .toml
        case "ini", "cfg", "conf":
            return .ini
        case "pdf":
            return .pdf
            
        // Programming languages
        case "swift":
            return .code(language: "swift")
        case "m", "mm":
            return .code(language: "objectivec")
        case "h", "hpp":
            return .code(language: "cpp")
        case "c":
            return .code(language: "c")
        case "cpp", "cc", "cxx", "c++":
            return .code(language: "cpp")
        case "js", "mjs", "cjs":
            return .code(language: "javascript")
        case "jsx":
            return .code(language: "jsx")
        case "ts", "mts", "cts":
            return .code(language: "typescript")
        case "tsx":
            return .code(language: "tsx")
        case "py", "pyw":
            return .code(language: "python")
        case "rb":
            return .code(language: "ruby")
        case "java":
            return .code(language: "java")
        case "kt", "kts":
            return .code(language: "kotlin")
        case "go":
            return .code(language: "go")
        case "rs":
            return .code(language: "rust")
        case "php":
            return .code(language: "php")
        case "sh", "bash", "zsh":
            return .code(language: "bash")
        case "ps1", "psm1", "psd1":
            return .code(language: "powershell")
        case "sql":
            return .code(language: "sql")
        case "html", "htm":
            return .code(language: "html")
        case "css":
            return .code(language: "css")
        case "scss", "sass":
            return .code(language: "scss")
        case "less":
            return .code(language: "less")
        case "r":
            return .code(language: "r")
        case "matlab", "m":
            return .code(language: "matlab")
        case "scala":
            return .code(language: "scala")
        case "groovy":
            return .code(language: "groovy")
        case "lua":
            return .code(language: "lua")
        case "dart":
            return .code(language: "dart")
        case "vue":
            return .code(language: "vue")
        case "svelte":
            return .code(language: "svelte")
        case "elm":
            return .code(language: "elm")
        case "clj", "cljs", "cljc":
            return .code(language: "clojure")
        case "ex", "exs":
            return .code(language: "elixir")
        case "erl", "hrl":
            return .code(language: "erlang")
        case "fs", "fsi", "fsx":
            return .code(language: "fsharp")
        case "ml", "mli":
            return .code(language: "ocaml")
        case "nim":
            return .code(language: "nim")
        case "cr":
            return .code(language: "crystal")
        case "jl":
            return .code(language: "julia")
        case "zig":
            return .code(language: "zig")
        case "v":
            return .code(language: "v")
        case "pl", "pm":
            return .code(language: "perl")
        case "hs":
            return .code(language: "haskell")
        case "cs":
            return .code(language: "csharp")
        case "vb":
            return .code(language: "vbnet")
        case "pas", "pp":
            return .code(language: "pascal")
        case "d":
            return .code(language: "d")
        case "diff", "patch":
            return .code(language: "diff")
        case "cmake":
            return .code(language: "cmake")
        case "adoc", "asciidoc":
            return .code(language: "asciidoc")
        case "xsd":
            return .code(language: "xml")
        case "dic", "dict":
            return .text
            
        // Text files
        case "txt", "text", "log":
            return .text
            
        default:
            // Check by filename patterns
            if fileName == "Dockerfile" || fileName.hasPrefix("Dockerfile.") {
                return .code(language: "dockerfile")
            } else if fileName == "Makefile" || fileName.hasSuffix(".mk") {
                return .code(language: "makefile")
            } else if fileName == "Gemfile" || fileName == "Rakefile" {
                return .code(language: "ruby")
            } else if fileName == "Package.swift" {
                return .code(language: "swift")
            } else if fileName == ".gitignore" || fileName == ".dockerignore" {
                return .code(language: "gitignore")
            } else if fileName == ".clang-format" || fileName == ".clang-tidy" {
                return .code(language: "yaml")
            }
            
            // Check content for shebang
            if let content = content, !content.isEmpty {
                let firstLine = content.components(separatedBy: .newlines).first ?? ""
                if firstLine.hasPrefix("#!") {
                    if firstLine.contains("python") {
                        return .code(language: "python")
                    } else if firstLine.contains("bash") || firstLine.contains("sh") {
                        return .code(language: "bash")
                    } else if firstLine.contains("ruby") {
                        return .code(language: "ruby")
                    } else if firstLine.contains("node") || firstLine.contains("javascript") {
                        return .code(language: "javascript")
                    } else if firstLine.contains("perl") {
                        return .code(language: "perl")
                    }
                }
                
                // Check if it's likely binary using raw data if available
                if let data = data, isBinaryData(data) {
                    return .binary
                }
            }
            
            // If we have raw data but no content (encoding failed), check if binary
            if let data = data, (content?.isEmpty ?? true) && !data.isEmpty {
                if isBinaryData(data) {
                    return .binary
                } else {
                    // It's a text file with encoding issues
                    return .text
                }
            }
            
            return .unknown
        }
    }
    
    static func isBinaryData(_ data: Data) -> Bool {
        // Check first 8192 bytes for binary content
        let sampleSize = min(data.count, 8192)
        let sample = data.prefix(sampleSize)
        
        var nullCount = 0
        var controlCount = 0
        
        for byte in sample {
            if byte == 0 {
                nullCount += 1
            } else if byte < 32 && byte != 9 && byte != 10 && byte != 13 {
                controlCount += 1
            }
        }
        
        // If more than 30% null bytes or control characters, likely binary
        let threshold = Double(sampleSize) * 0.3
        return Double(nullCount) > threshold || Double(controlCount) > threshold
    }
    
    static func mimeType(for fileType: FileType) -> String {
        switch fileType {
        case .markdown:
            return "text/markdown"
        case .code:
            return "text/plain"
        case .json:
            return "application/json"
        case .xml:
            return "application/xml"
        case .yaml:
            return "application/x-yaml"
        case .toml:
            return "application/toml"
        case .ini:
            return "text/plain"
        case .image(let type):
            switch type {
            case "svg":
                return "image/svg+xml"
            case "png":
                return "image/png"
            case "jpg", "jpeg":
                return "image/jpeg"
            case "gif":
                return "image/gif"
            case "webp":
                return "image/webp"
            default:
                return "image/\(type)"
            }
        case .pdf:
            return "application/pdf"
        case .text:
            return "text/plain"
        case .binary:
            return "application/octet-stream"
        case .unknown:
            return "text/plain"
        }
    }
}