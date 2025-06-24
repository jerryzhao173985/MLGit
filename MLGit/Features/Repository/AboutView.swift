import Foundation
import SwiftUI

struct AboutView: View {
    let repository: Repository
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let readme = repository.readme, !readme.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("README")
                            .font(.headline)
                        
                        Text(readme)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Repository Info")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Name", value: repository.name)
                        InfoRow(label: "Path", value: repository.path)
                        if let description = repository.description {
                            InfoRow(label: "Description", value: description)
                        }
                        InfoRow(label: "Default Branch", value: repository.defaultBranch)
                        if let lastUpdate = repository.lastUpdate {
                            InfoRow(label: "Last Updated", value: lastUpdate.formatted())
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actions")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Link(destination: repository.fullURL) {
                            Label("View on Web", systemImage: "safari")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        ShareLink(item: repository.fullURL) {
                            Label("Share Repository", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}
