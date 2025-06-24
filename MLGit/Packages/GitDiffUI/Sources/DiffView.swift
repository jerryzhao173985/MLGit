import SwiftUI
import Highlightr

public struct DiffView: View {
    let diff: String
    
    public init(diff: String) {
        self.diff = diff
    }
    
    public var body: some View {
        ScrollView {
            Text(diff)
                .font(.system(.body, design: .monospaced))
                .padding()
        }
    }
}