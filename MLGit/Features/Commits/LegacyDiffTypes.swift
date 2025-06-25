import Foundation
import SwiftUI

// Legacy Diff Types - Use EnhancedDiffView for new features

struct LegacyDiffFile: Identifiable {
    let id = UUID()
    let path: String
    let oldPath: String?
    let changeType: ChangeType
    let additions: Int
    let deletions: Int
    let hunks: [LegacyDiffHunk]
    
    enum ChangeType {
        case added, modified, deleted, renamed, copied
    }
}

struct LegacyDiffHunk: Identifiable {
    let id = UUID()
    let header: String
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let lines: [LegacyDiffLine]
}

struct LegacyDiffLine: Identifiable {
    let id = UUID()
    let type: LineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?
    
    enum LineType {
        case addition
        case deletion
        case context
        
        var indicator: String {
            switch self {
            case .addition: return "+"
            case .deletion: return "-"
            case .context: return " "
            }
        }
        
        var color: Color {
            switch self {
            case .addition: return .green
            case .deletion: return .red
            case .context: return .secondary
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .addition: return Color.green.opacity(0.1)
            case .deletion: return Color.red.opacity(0.1)
            case .context: return Color.clear
            }
        }
        
        var contentColor: Color {
            switch self {
            case .addition: return .primary
            case .deletion: return .primary
            case .context: return .secondary
            }
        }
    }
}