import SwiftUI

struct DeveloperSettingsView: View {
    @AppStorage("MLGitDebugMode") private var debugMode = false
    @AppStorage("MLGitShowNetworkLogs") private var showNetworkLogs = false
    @AppStorage("MLGitCacheSize") private var cacheSize = 100
    @State private var showingClearCacheAlert = false
    @State private var showingDebugLogsSheet = false
    @State private var debugLogs: [URL] = []
    
    var body: some View {
        Form {
            Section {
                Toggle("Debug Mode", isOn: $debugMode)
                    .onChange(of: debugMode) { newValue in
                        HTMLDebugLogger.shared.setEnabled(newValue)
                    }
                
                Toggle("Show Network Logs", isOn: $showNetworkLogs)
                
                if debugMode {
                    Button("View Debug Logs") {
                        debugLogs = HTMLDebugLogger.shared.getSavedLogs()
                        showingDebugLogsSheet = true
                    }
                    
                    Button("Clear Debug Logs") {
                        Task {
                            await HTMLDebugLogger.shared.clearLogs()
                        }
                    }
                    .foregroundColor(.red)
                }
            } header: {
                Text("Debugging")
            } footer: {
                if debugMode {
                    Text("Debug logs are saved to: \(HTMLDebugLogger.shared.debugDirectoryPath)")
                        .font(.caption)
                }
            }
            
            Section {
                HStack {
                    Text("Cache Size Limit")
                    Spacer()
                    Text("\(cacheSize) MB")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(cacheSize) },
                    set: { cacheSize = Int($0) }
                ), in: 50...500, step: 50)
                
                Button("Clear Cache") {
                    showingClearCacheAlert = true
                }
                .foregroundColor(.red)
            } header: {
                Text("Cache Management")
            }
            
            Section {
                NavigationLink("Feature Flags") {
                    FeatureFlagsView()
                }
                
                NavigationLink("Network Inspector") {
                    NetworkInspectorView()
                }
                
                NavigationLink("Performance Metrics") {
                    PerformanceMetricsView()
                }
            } header: {
                Text("Advanced Tools")
            }
            
            Section {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build Number")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("iOS Version")
                    Spacer()
                    Text(UIDevice.current.systemVersion)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("System Information")
            }
        }
        .navigationTitle("Developer Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await RequestManager.shared.clearCache()
                }
            }
        } message: {
            Text("This will clear all cached data. The app will need to re-fetch content from the server.")
        }
        .sheet(isPresented: $showingDebugLogsSheet) {
            DebugLogsListView(logs: debugLogs)
        }
    }
}

struct DebugLogsListView: View {
    let logs: [URL]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(logs, id: \.self) { logURL in
                VStack(alignment: .leading) {
                    Text(logURL.lastPathComponent)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                    
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: logURL.path),
                       let size = attributes[.size] as? Int64,
                       let date = attributes[.creationDate] as? Date {
                        HStack {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Placeholder views for advanced tools
struct FeatureFlagsView: View {
    var body: some View {
        List {
            Text("Feature flags coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Feature Flags")
    }
}

struct NetworkInspectorView: View {
    var body: some View {
        List {
            Text("Network inspector coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Network Inspector")
    }
}

struct PerformanceMetricsView: View {
    var body: some View {
        List {
            Text("Performance metrics coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Performance Metrics")
    }
}

struct DeveloperSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeveloperSettingsView()
        }
    }
}