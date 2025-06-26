import SwiftUI

struct JSONFileView: View {
    let content: String
    let fontSize: CGFloat
    
    @State private var prettyPrinted: String = ""
    @State private var error: String?
    @State private var expandedNodes: Set<String> = []
    @State private var showRaw = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Toggle("Show Raw", isOn: $showRaw)
                    .toggleStyle(.button)
                    .font(.caption)
                
                Spacer()
                
                if !showRaw {
                    Button(action: expandAll) {
                        Label("Expand All", systemImage: "arrow.down.right.and.arrow.up.left")
                            .font(.caption)
                    }
                    
                    Button(action: collapseAll) {
                        Label("Collapse All", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            
            Divider()
            
            // Content
            ScrollView([.horizontal, .vertical]) {
                if let error = error {
                    ErrorMessageView(error: error, fontSize: fontSize)
                } else if showRaw {
                    RawJSONView(content: prettyPrinted.isEmpty ? content : prettyPrinted, fontSize: fontSize)
                } else {
                    InteractiveJSONView(
                        content: content,
                        fontSize: fontSize,
                        expandedNodes: $expandedNodes
                    )
                }
            }
        }
        .onAppear {
            formatJSON()
        }
    }
    
    private func formatJSON() {
        do {
            guard let data = content.data(using: .utf8) else {
                error = "Invalid UTF-8 data"
                return
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(
                withJSONObject: jsonObject,
                options: [.prettyPrinted, .sortedKeys]
            )
            
            prettyPrinted = String(data: prettyData, encoding: .utf8) ?? content
            error = nil
        } catch {
            self.error = "Invalid JSON: \(error.localizedDescription)"
            prettyPrinted = content
        }
    }
    
    private func expandAll() {
        // This would need to be implemented with the interactive view
    }
    
    private func collapseAll() {
        expandedNodes.removeAll()
    }
}

// MARK: - Raw JSON View

struct RawJSONView: View {
    let content: String
    let fontSize: CGFloat
    
    var body: some View {
        Text(content)
            .font(.system(size: fontSize, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding()
    }
}

// MARK: - Interactive JSON View

struct InteractiveJSONView: View {
    let content: String
    let fontSize: CGFloat
    @Binding var expandedNodes: Set<String>
    
    @State private var jsonTree: JSONNode?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let jsonTree = jsonTree {
                JSONNodeView(
                    node: jsonTree,
                    fontSize: fontSize,
                    expandedNodes: $expandedNodes,
                    level: 0,
                    path: ""
                )
            } else {
                Text("Parsing JSON...")
                    .font(.system(size: fontSize))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            parseJSON()
        }
    }
    
    private func parseJSON() {
        guard let data = content.data(using: .utf8) else { return }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            jsonTree = JSONNode.from(jsonObject, key: "root")
        } catch {
            jsonTree = JSONNode(key: "error", value: .string(error.localizedDescription))
        }
    }
}

// MARK: - JSON Node Model

enum JSONValue {
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case null
    case array([JSONNode])
    case object([JSONNode])
}

struct JSONNode: Identifiable {
    let id = UUID()
    let key: String
    let value: JSONValue
    
    static func from(_ object: Any, key: String) -> JSONNode {
        switch object {
        case let string as String:
            return JSONNode(key: key, value: .string(string))
        case let number as NSNumber:
            if number.isBool {
                return JSONNode(key: key, value: .bool(number.boolValue))
            } else {
                return JSONNode(key: key, value: .number(number))
            }
        case let array as [Any]:
            let nodes = array.enumerated().map { index, item in
                JSONNode.from(item, key: "\(index)")
            }
            return JSONNode(key: key, value: .array(nodes))
        case let dict as [String: Any]:
            let nodes = dict.sorted { $0.key < $1.key }.map { key, value in
                JSONNode.from(value, key: key)
            }
            return JSONNode(key: key, value: .object(nodes))
        case is NSNull:
            return JSONNode(key: key, value: .null)
        default:
            return JSONNode(key: key, value: .string("\(object)"))
        }
    }
}

// MARK: - JSON Node View

struct JSONNodeView: View {
    let node: JSONNode
    let fontSize: CGFloat
    @Binding var expandedNodes: Set<String>
    let level: Int
    let path: String
    
    private var nodePath: String {
        path.isEmpty ? node.key : "\(path).\(node.key)"
    }
    
    private var isExpanded: Bool {
        expandedNodes.contains(nodePath)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch node.value {
            case .string(let value):
                simpleValueView(key: node.key, value: "\"\(value)\"", color: .green)
                
            case .number(let value):
                simpleValueView(key: node.key, value: "\(value)", color: .blue)
                
            case .bool(let value):
                simpleValueView(key: node.key, value: "\(value)", color: .purple)
                
            case .null:
                simpleValueView(key: node.key, value: "null", color: .gray)
                
            case .array(let nodes):
                collapsibleView(
                    key: node.key,
                    bracket: ("[", "]"),
                    count: nodes.count,
                    itemLabel: "items"
                ) {
                    ForEach(nodes) { childNode in
                        JSONNodeView(
                            node: childNode,
                            fontSize: fontSize,
                            expandedNodes: $expandedNodes,
                            level: level + 1,
                            path: nodePath
                        )
                    }
                }
                
            case .object(let nodes):
                collapsibleView(
                    key: node.key,
                    bracket: ("{", "}"),
                    count: nodes.count,
                    itemLabel: "properties"
                ) {
                    ForEach(nodes) { childNode in
                        JSONNodeView(
                            node: childNode,
                            fontSize: fontSize,
                            expandedNodes: $expandedNodes,
                            level: level + 1,
                            path: nodePath
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func simpleValueView(key: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            indentation
            
            Text("\(key):")
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.primary)
            
            Text(value)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(color)
        }
    }
    
    @ViewBuilder
    private func collapsibleView<Content: View>(
        key: String,
        bracket: (String, String),
        count: Int,
        itemLabel: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: toggleExpanded) {
                HStack(spacing: 4) {
                    indentation
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: fontSize - 4))
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                    
                    Text("\(key):")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text(bracket.0)
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    if !isExpanded {
                        Text("... \(count) \(itemLabel)")
                            .font(.system(size: fontSize - 2))
                            .foregroundColor(.secondary)
                            .italic()
                        
                        Text(bracket.1)
                            .font(.system(size: fontSize, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                content()
                
                HStack(spacing: 4) {
                    indentation
                    Text(bracket.1)
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var indentation: some View {
        HStack(spacing: 0) {
            ForEach(0..<level, id: \.self) { _ in
                Text("  ")
                    .font(.system(size: fontSize, design: .monospaced))
            }
        }
    }
    
    private func toggleExpanded() {
        if isExpanded {
            expandedNodes.remove(nodePath)
        } else {
            expandedNodes.insert(nodePath)
        }
    }
}

// MARK: - Error Message View

struct ErrorMessageView: View {
    let error: String
    let fontSize: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("JSON Parse Error", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error)
                .font(.system(size: fontSize))
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Helpers

extension NSNumber {
    var isBool: Bool {
        CFBooleanGetTypeID() == CFGetTypeID(self)
    }
}