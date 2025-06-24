import SwiftUI

struct OfflineModeView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showingOfflineInfo = false
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                
                Text("Offline Mode")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Button(action: { showingOfflineInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange)
            .cornerRadius(20)
            .shadow(radius: 2)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .sheet(isPresented: $showingOfflineInfo) {
                OfflineInfoSheet()
            }
        }
    }
}

struct OfflineInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var cacheSize: String = "Calculating..."
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Offline Mode Active", systemImage: "wifi.slash")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("You're currently offline. Some features may be limited.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "checkmark.circle.fill",
                        title: "Available Offline",
                        items: [
                            "• Starred repositories",
                            "• Recently viewed content",
                            "• Cached repository data"
                        ],
                        iconColor: .green
                    )
                    
                    FeatureRow(
                        icon: "xmark.circle.fill",
                        title: "Requires Internet",
                        items: [
                            "• Fetching new repositories",
                            "• Updating repository data",
                            "• Viewing uncached content"
                        ],
                        iconColor: .red
                    )
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cache Information")
                        .font(.headline)
                    
                    HStack {
                        Label("Cache Size:", systemImage: "internaldrive")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(cacheSize)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: clearCache) {
                        Label("Clear Cache", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Offline Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadCacheSize()
        }
    }
    
    private func loadCacheSize() async {
        let size = await CacheManager.shared.getCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        cacheSize = formatter.string(fromByteCount: size)
    }
    
    private func clearCache() {
        Task {
            await CacheManager.shared.clearCache()
            await loadCacheSize()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let items: [String]
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 28)
        }
    }
}

// MARK: - View Extension

extension View {
    func offlineModeIndicator() -> some View {
        self.safeAreaInset(edge: .bottom) {
            OfflineModeView()
        }
    }
}

struct OfflineModeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            OfflineModeView()
                .environmentObject(NetworkMonitor.shared)
        }
        
        OfflineInfoSheet()
    }
}