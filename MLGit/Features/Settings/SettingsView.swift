import Foundation
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showingClearCacheAlert = false
    @State private var showingResetAlert = false
    
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $viewModel.selectedTheme) {
                    Text("System").tag(Theme.system)
                    Text("Light").tag(Theme.light)
                    Text("Dark").tag(Theme.dark)
                }
                .onChange(of: viewModel.selectedTheme) { newTheme in
                    viewModel.updateTheme(newTheme)
                    appState.preferredColorScheme = newTheme.colorScheme
                }
            }
            
            Section("Cache") {
                HStack {
                    Text("Cache Size")
                    Spacer()
                    Text(viewModel.cacheSize)
                        .foregroundColor(.secondary)
                }
                
                Button("Clear Cache") {
                    showingClearCacheAlert = true
                }
                .foregroundColor(.red)
            }
            
            Section("Data") {
                HStack {
                    Text("Starred Projects")
                    Spacer()
                    Text("\(viewModel.starredCount)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Notes")
                    Spacer()
                    Text("\(viewModel.notesCount)")
                        .foregroundColor(.secondary)
                }
                
                Button("Reset All Data") {
                    showingResetAlert = true
                }
                .foregroundColor(.red)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(viewModel.appVersion)
                        .foregroundColor(.secondary)
                }
                
                Link("Visit git.mlplatform.org", destination: URL(string: "https://git.mlplatform.org")!)
                
                Link("About MLGit", destination: URL(string: "https://git.mlplatform.org/about")!)
            }
        }
        .navigationTitle("Settings")
        .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                viewModel.clearCache()
            }
        } message: {
            Text("This will remove all cached data. You will need to fetch data again.")
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetAllData()
            }
        } message: {
            Text("This will remove all starred projects, notes, and cached data. This action cannot be undone.")
        }
        .onAppear {
            viewModel.loadStats()
        }
    }
}

enum Theme: String, CaseIterable {
    case system
    case light
    case dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(AppState())
        }
    }
}
