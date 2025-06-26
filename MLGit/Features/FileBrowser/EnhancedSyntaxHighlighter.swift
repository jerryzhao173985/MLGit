import SwiftUI

/// Token types for syntax highlighting
enum TokenType {
    case keyword
    case string
    case comment
    case number
    case function
    case variable
    case operatorSymbol
    case preprocessor
    case type
    case plain
}

/// Token representation
struct Token {
    let text: String
    let type: TokenType
}

/// Enhanced syntax highlighter with proper tokenization
struct EnhancedSyntaxHighlighter {
    
    // MARK: - Python Tokenizer
    static func tokenizePython(_ line: String) -> [Token] {
        let pythonKeywords = Set([
            "and", "as", "assert", "async", "await", "break", "class", "continue",
            "def", "del", "elif", "else", "except", "False", "finally", "for",
            "from", "global", "if", "import", "in", "is", "lambda", "None",
            "nonlocal", "not", "or", "pass", "raise", "return", "True", "try",
            "while", "with", "yield", "__init__", "self"
        ])
        
        let pythonBuiltins = Set([
            "print", "len", "range", "str", "int", "float", "list", "dict",
            "set", "tuple", "open", "file", "input", "format", "sorted",
            "enumerate", "zip", "map", "filter", "sum", "min", "max", "abs"
        ])
        
        var tokens: [Token] = []
        var currentToken = ""
        var inString = false
        var stringChar: Character?
        var inComment = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            // Handle comments
            if !inString && char == "#" {
                if !currentToken.isEmpty {
                    tokens.append(Token(text: currentToken, type: .plain))
                    currentToken = ""
                }
                tokens.append(Token(text: String(line[i...]), type: .comment))
                break
            }
            
            // Handle strings
            if !inComment {
                if inString {
                    currentToken.append(char)
                    if char == stringChar && (i == line.startIndex || line[line.index(before: i)] != "\\") {
                        tokens.append(Token(text: currentToken, type: .string))
                        currentToken = ""
                        inString = false
                        stringChar = nil
                    }
                } else if char == "\"" || char == "'" {
                    if !currentToken.isEmpty {
                        tokens.append(classifyPythonToken(currentToken, keywords: pythonKeywords, builtins: pythonBuiltins))
                        currentToken = ""
                    }
                    inString = true
                    stringChar = char
                    currentToken.append(char)
                } else if char == " " || char == "\t" || "()[]{}:,;=+-*/<>!&|".contains(char) {
                    if !currentToken.isEmpty {
                        tokens.append(classifyPythonToken(currentToken, keywords: pythonKeywords, builtins: pythonBuiltins))
                        currentToken = ""
                    }
                    if char == " " || char == "\t" {
                        tokens.append(Token(text: String(char), type: .plain))
                    } else {
                        tokens.append(Token(text: String(char), type: .operatorSymbol))
                    }
                } else {
                    currentToken.append(char)
                }
            }
            
            i = line.index(after: i)
        }
        
        if !currentToken.isEmpty && !inComment {
            if inString {
                tokens.append(Token(text: currentToken, type: .string))
            } else {
                tokens.append(classifyPythonToken(currentToken, keywords: pythonKeywords, builtins: pythonBuiltins))
            }
        }
        
        return tokens
    }
    
    private static func classifyPythonToken(_ token: String, keywords: Set<String>, builtins: Set<String>) -> Token {
        if keywords.contains(token) {
            return Token(text: token, type: .keyword)
        } else if builtins.contains(token) {
            return Token(text: token, type: .function)
        } else if token.allSatisfy({ $0.isNumber || $0 == "." }) && token.contains(where: { $0.isNumber }) {
            return Token(text: token, type: .number)
        } else {
            return Token(text: token, type: .plain)
        }
    }
    
    // MARK: - C/C++ Tokenizer
    static func tokenizeCpp(_ line: String) -> [Token] {
        let cppKeywords = Set([
            "auto", "break", "case", "char", "const", "continue", "default", "do",
            "double", "else", "enum", "extern", "float", "for", "goto", "if",
            "int", "long", "register", "return", "short", "signed", "sizeof", "static",
            "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while",
            "class", "namespace", "template", "public", "private", "protected", "virtual",
            "override", "final", "new", "delete", "try", "catch", "throw", "using",
            "bool", "true", "false", "nullptr"
        ])
        
        let cppTypes = Set([
            "std::string", "std::vector", "std::map", "std::set", "std::pair",
            "size_t", "uint8_t", "uint16_t", "uint32_t", "uint64_t",
            "int8_t", "int16_t", "int32_t", "int64_t"
        ])
        
        var tokens: [Token] = []
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Handle preprocessor directives
        if trimmed.hasPrefix("#") {
            tokens.append(Token(text: line, type: .preprocessor))
            return tokens
        }
        
        // Handle single line comments
        if trimmed.hasPrefix("//") {
            tokens.append(Token(text: line, type: .comment))
            return tokens
        }
        
        var currentToken = ""
        var inString = false
        var stringChar: Character?
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            // Handle strings
            if inString {
                currentToken.append(char)
                if char == stringChar && (i == line.startIndex || line[line.index(before: i)] != "\\") {
                    tokens.append(Token(text: currentToken, type: .string))
                    currentToken = ""
                    inString = false
                    stringChar = nil
                }
            } else if char == "\"" || char == "'" {
                if !currentToken.isEmpty {
                    tokens.append(classifyCppToken(currentToken, keywords: cppKeywords, types: cppTypes))
                    currentToken = ""
                }
                inString = true
                stringChar = char
                currentToken.append(char)
            } else if char == " " || char == "\t" || "()[]{}:,;=+-*/<>!&|".contains(char) {
                if !currentToken.isEmpty {
                    tokens.append(classifyCppToken(currentToken, keywords: cppKeywords, types: cppTypes))
                    currentToken = ""
                }
                if char == " " || char == "\t" {
                    tokens.append(Token(text: String(char), type: .plain))
                } else {
                    tokens.append(Token(text: String(char), type: .operatorSymbol))
                }
            } else {
                currentToken.append(char)
            }
            
            i = line.index(after: i)
        }
        
        if !currentToken.isEmpty {
            if inString {
                tokens.append(Token(text: currentToken, type: .string))
            } else {
                tokens.append(classifyCppToken(currentToken, keywords: cppKeywords, types: cppTypes))
            }
        }
        
        return tokens
    }
    
    private static func classifyCppToken(_ token: String, keywords: Set<String>, types: Set<String>) -> Token {
        if keywords.contains(token) {
            return Token(text: token, type: .keyword)
        } else if types.contains(token) || token.hasSuffix("_t") {
            return Token(text: token, type: .type)
        } else if token.allSatisfy({ $0.isNumber || $0 == "." || $0 == "f" || $0 == "L" }) && token.contains(where: { $0.isNumber }) {
            return Token(text: token, type: .number)
        } else if token.contains("(") {
            return Token(text: token, type: .function)
        } else {
            return Token(text: token, type: .plain)
        }
    }
    
    // MARK: - Shell/Bash Tokenizer
    static func tokenizeShell(_ line: String) -> [Token] {
        let shellKeywords = Set([
            "if", "then", "else", "elif", "fi", "for", "while", "do", "done",
            "case", "esac", "function", "return", "break", "continue", "exit",
            "export", "source", "alias", "unset", "readonly", "local", "declare"
        ])
        
        let shellBuiltins = Set([
            "echo", "cd", "pwd", "ls", "cp", "mv", "rm", "mkdir", "rmdir",
            "cat", "grep", "sed", "awk", "find", "sort", "uniq", "head", "tail",
            "chmod", "chown", "touch", "date", "whoami", "hostname", "which"
        ])
        
        var tokens: [Token] = []
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Handle comments
        if trimmed.hasPrefix("#") {
            tokens.append(Token(text: line, type: .comment))
            return tokens
        }
        
        var currentToken = ""
        var inString = false
        var stringChar: Character?
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if inString {
                currentToken.append(char)
                if char == stringChar && (i == line.startIndex || line[line.index(before: i)] != "\\") {
                    tokens.append(Token(text: currentToken, type: .string))
                    currentToken = ""
                    inString = false
                    stringChar = nil
                }
            } else if char == "\"" || char == "'" {
                if !currentToken.isEmpty {
                    tokens.append(classifyShellToken(currentToken, keywords: shellKeywords, builtins: shellBuiltins))
                    currentToken = ""
                }
                inString = true
                stringChar = char
                currentToken.append(char)
            } else if char == "$" {
                if !currentToken.isEmpty {
                    tokens.append(classifyShellToken(currentToken, keywords: shellKeywords, builtins: shellBuiltins))
                    currentToken = ""
                }
                // Variable reference
                var varName = "$"
                i = line.index(after: i)
                while i < line.endIndex && (line[i].isLetter || line[i].isNumber || line[i] == "_") {
                    varName.append(line[i])
                    i = line.index(after: i)
                }
                tokens.append(Token(text: varName, type: .variable))
                continue
            } else if char == " " || char == "\t" || "|&;<>()[]{}=".contains(char) {
                if !currentToken.isEmpty {
                    tokens.append(classifyShellToken(currentToken, keywords: shellKeywords, builtins: shellBuiltins))
                    currentToken = ""
                }
                if char == " " || char == "\t" {
                    tokens.append(Token(text: String(char), type: .plain))
                } else {
                    tokens.append(Token(text: String(char), type: .operatorSymbol))
                }
            } else {
                currentToken.append(char)
            }
            
            i = line.index(after: i)
        }
        
        if !currentToken.isEmpty {
            if inString {
                tokens.append(Token(text: currentToken, type: .string))
            } else {
                tokens.append(classifyShellToken(currentToken, keywords: shellKeywords, builtins: shellBuiltins))
            }
        }
        
        return tokens
    }
    
    private static func classifyShellToken(_ token: String, keywords: Set<String>, builtins: Set<String>) -> Token {
        if keywords.contains(token) {
            return Token(text: token, type: .keyword)
        } else if builtins.contains(token) {
            return Token(text: token, type: .function)
        } else if token.allSatisfy({ $0.isNumber }) {
            return Token(text: token, type: .number)
        } else {
            return Token(text: token, type: .plain)
        }
    }
    
    // MARK: - JavaScript/TypeScript Tokenizer
    static func tokenizeJavaScript(_ line: String) -> [Token] {
        let jsKeywords = Set([
            "async", "await", "break", "case", "catch", "class", "const", "continue",
            "debugger", "default", "delete", "do", "else", "export", "extends", "finally",
            "for", "function", "if", "import", "in", "instanceof", "let", "new", "return",
            "super", "switch", "this", "throw", "try", "typeof", "var", "void", "while",
            "with", "yield", "enum", "implements", "interface", "package", "private",
            "protected", "public", "static", "null", "undefined", "true", "false"
        ])
        
        let jsBuiltins = Set([
            "console", "window", "document", "Array", "Object", "String", "Number",
            "Boolean", "Function", "Promise", "Map", "Set", "Date", "Math", "JSON",
            "parseInt", "parseFloat", "isNaN", "isFinite", "encodeURI", "decodeURI"
        ])
        
        var tokens: [Token] = []
        var currentToken = ""
        var inString = false
        var stringChar: Character?
        var inComment = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            // Handle single-line comments
            if !inString && i < line.index(before: line.endIndex) && char == "/" && line[line.index(after: i)] == "/" {
                if !currentToken.isEmpty {
                    tokens.append(classifyJavaScriptToken(currentToken, keywords: jsKeywords, builtins: jsBuiltins))
                    currentToken = ""
                }
                tokens.append(Token(text: String(line[i...]), type: .comment))
                break
            }
            
            // Handle strings
            if !inComment {
                if inString {
                    currentToken.append(char)
                    if char == stringChar && (i == line.startIndex || line[line.index(before: i)] != "\\") {
                        tokens.append(Token(text: currentToken, type: .string))
                        currentToken = ""
                        inString = false
                        stringChar = nil
                    }
                } else if char == "\"" || char == "'" || char == "`" {
                    if !currentToken.isEmpty {
                        tokens.append(classifyJavaScriptToken(currentToken, keywords: jsKeywords, builtins: jsBuiltins))
                        currentToken = ""
                    }
                    inString = true
                    stringChar = char
                    currentToken.append(char)
                } else if char == " " || char == "\t" || "()[]{}:,;=+-*/<>!&|?.".contains(char) {
                    if !currentToken.isEmpty {
                        tokens.append(classifyJavaScriptToken(currentToken, keywords: jsKeywords, builtins: jsBuiltins))
                        currentToken = ""
                    }
                    if char == " " || char == "\t" {
                        tokens.append(Token(text: String(char), type: .plain))
                    } else {
                        tokens.append(Token(text: String(char), type: .operatorSymbol))
                    }
                } else {
                    currentToken.append(char)
                }
            }
            
            i = line.index(after: i)
        }
        
        if !currentToken.isEmpty && !inComment {
            if inString {
                tokens.append(Token(text: currentToken, type: .string))
            } else {
                tokens.append(classifyJavaScriptToken(currentToken, keywords: jsKeywords, builtins: jsBuiltins))
            }
        }
        
        return tokens
    }
    
    private static func classifyJavaScriptToken(_ token: String, keywords: Set<String>, builtins: Set<String>) -> Token {
        if keywords.contains(token) {
            return Token(text: token, type: .keyword)
        } else if builtins.contains(token) {
            return Token(text: token, type: .function)
        } else if token.allSatisfy({ $0.isNumber || $0 == "." }) && token.contains(where: { $0.isNumber }) {
            return Token(text: token, type: .number)
        } else if token.contains("(") || token.hasSuffix("()") {
            return Token(text: token, type: .function)
        } else {
            return Token(text: token, type: .plain)
        }
    }
    
    // MARK: - Swift Tokenizer
    static func tokenizeSwift(_ line: String) -> [Token] {
        let swiftKeywords = Set([
            "as", "associatedtype", "break", "case", "catch", "class", "continue", "default",
            "defer", "deinit", "do", "else", "enum", "extension", "fallthrough", "false",
            "fileprivate", "final", "for", "func", "guard", "if", "import", "in", "init",
            "inout", "internal", "is", "let", "nil", "open", "operator", "override", "private",
            "protocol", "public", "repeat", "rethrows", "return", "self", "Self", "static",
            "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias",
            "var", "where", "while", "@available", "@objc", "@IBAction", "@IBOutlet",
            "@MainActor", "@Published", "@State", "@StateObject", "@ObservedObject",
            "@Environment", "@EnvironmentObject", "@Binding", "@escaping", "async", "await", "actor"
        ])
        
        let swiftTypes = Set([
            "Int", "Double", "Float", "Bool", "String", "Character", "Array", "Dictionary",
            "Set", "Optional", "Any", "AnyObject", "Void", "Never", "Result", "Error",
            "Data", "Date", "URL", "UUID", "CGFloat", "CGPoint", "CGSize", "CGRect",
            "UIView", "UIViewController", "View", "Text", "Image", "Button", "List"
        ])
        
        var tokens: [Token] = []
        var currentToken = ""
        var inString = false
        var stringChar: Character?
        var inComment = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            // Handle single-line comments
            if !inString && i < line.index(before: line.endIndex) && char == "/" && line[line.index(after: i)] == "/" {
                if !currentToken.isEmpty {
                    tokens.append(classifySwiftToken(currentToken, keywords: swiftKeywords, types: swiftTypes))
                    currentToken = ""
                }
                tokens.append(Token(text: String(line[i...]), type: .comment))
                break
            }
            
            // Handle strings
            if !inComment {
                if inString {
                    currentToken.append(char)
                    if char == stringChar && (i == line.startIndex || line[line.index(before: i)] != "\\") {
                        tokens.append(Token(text: currentToken, type: .string))
                        currentToken = ""
                        inString = false
                        stringChar = nil
                    }
                } else if char == "\"" || char == "'" {
                    if !currentToken.isEmpty {
                        tokens.append(classifySwiftToken(currentToken, keywords: swiftKeywords, types: swiftTypes))
                        currentToken = ""
                    }
                    inString = true
                    stringChar = char
                    currentToken.append(char)
                } else if char == " " || char == "\t" || "()[]{}:,;=+-*/<>!&|?.".contains(char) {
                    if !currentToken.isEmpty {
                        tokens.append(classifySwiftToken(currentToken, keywords: swiftKeywords, types: swiftTypes))
                        currentToken = ""
                    }
                    if char == " " || char == "\t" {
                        tokens.append(Token(text: String(char), type: .plain))
                    } else {
                        tokens.append(Token(text: String(char), type: .operatorSymbol))
                    }
                } else {
                    currentToken.append(char)
                }
            }
            
            i = line.index(after: i)
        }
        
        if !currentToken.isEmpty && !inComment {
            if inString {
                tokens.append(Token(text: currentToken, type: .string))
            } else {
                tokens.append(classifySwiftToken(currentToken, keywords: swiftKeywords, types: swiftTypes))
            }
        }
        
        return tokens
    }
    
    private static func classifySwiftToken(_ token: String, keywords: Set<String>, types: Set<String>) -> Token {
        if keywords.contains(token) || token.hasPrefix("@") {
            return Token(text: token, type: .keyword)
        } else if types.contains(token) || token.first?.isUppercase == true {
            return Token(text: token, type: .type)
        } else if token.allSatisfy({ $0.isNumber || $0 == "." }) && token.contains(where: { $0.isNumber }) {
            return Token(text: token, type: .number)
        } else if token.contains("(") || token.hasSuffix("()") {
            return Token(text: token, type: .function)
        } else {
            return Token(text: token, type: .plain)
        }
    }
    
    // MARK: - Gitignore Tokenizer
    static func tokenizeGitignore(_ line: String) -> [Token] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.isEmpty {
            return [Token(text: line, type: .plain)]
        } else if trimmed.hasPrefix("#") {
            return [Token(text: line, type: .comment)]
        } else {
            // Pattern - check for special gitignore syntax
            var tokens: [Token] = []
            var currentToken = ""
            
            for char in line {
                if "*?[]!".contains(char) {
                    if !currentToken.isEmpty {
                        tokens.append(Token(text: currentToken, type: .plain))
                        currentToken = ""
                    }
                    tokens.append(Token(text: String(char), type: .operatorSymbol))
                } else {
                    currentToken.append(char)
                }
            }
            
            if !currentToken.isEmpty {
                tokens.append(Token(text: currentToken, type: .plain))
            }
            
            return tokens
        }
    }
}

/// View for rendering tokenized text
struct TokenizedTextView: View {
    let tokens: [Token]
    let fontSize: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                Text(token.text)
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(colorForToken(token))
            }
        }
    }
    
    private func colorForToken(_ token: Token) -> Color {
        switch token.type {
        case .keyword:
            return colorScheme == .dark ? Color(red: 0.68, green: 0.18, blue: 0.89) : Color(red: 0.68, green: 0.18, blue: 0.89)
        case .string:
            return colorScheme == .dark ? Color(red: 0.77, green: 0.10, blue: 0.09) : Color(red: 0.77, green: 0.10, blue: 0.09)
        case .comment:
            return colorScheme == .dark ? Color(red: 0.42, green: 0.47, blue: 0.53) : Color(red: 0.42, green: 0.47, blue: 0.53)
        case .number:
            return colorScheme == .dark ? Color(red: 0.13, green: 0.43, blue: 0.85) : Color(red: 0.13, green: 0.43, blue: 0.85)
        case .function:
            return colorScheme == .dark ? Color(red: 0.28, green: 0.68, blue: 0.86) : Color(red: 0.00, green: 0.46, blue: 0.96)
        case .variable:
            return colorScheme == .dark ? Color(red: 0.51, green: 0.77, blue: 0.64) : Color(red: 0.02, green: 0.60, blue: 0.30)
        case .operatorSymbol:
            return colorScheme == .dark ? Color(red: 0.86, green: 0.86, blue: 0.86) : Color(red: 0.36, green: 0.36, blue: 0.36)
        case .preprocessor:
            return colorScheme == .dark ? Color(red: 0.76, green: 0.49, blue: 0.29) : Color(red: 0.64, green: 0.21, blue: 0.00)
        case .type:
            return colorScheme == .dark ? Color(red: 0.42, green: 0.82, blue: 0.74) : Color(red: 0.00, green: 0.60, blue: 0.60)
        case .plain:
            return colorScheme == .dark ? Color(red: 0.85, green: 0.85, blue: 0.85) : Color(red: 0.15, green: 0.15, blue: 0.15)
        }
    }
}