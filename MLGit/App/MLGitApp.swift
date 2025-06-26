import Foundation
import SwiftUI
import Combine

@main
struct MLGitApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var navigationState = NavigationStateManager.shared
    @StateObject private var prefetchManager = PrefetchManager.shared
    @StateObject private var directoryCache = DirectoryCache.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(networkMonitor)
                .environmentObject(themeManager)
                .environmentObject(navigationState)
                .environmentObject(prefetchManager)
                .environmentObject(directoryCache)
                .preferredColorScheme(appState.preferredColorScheme)
                .environment(\.navigationStateManager, navigationState)
        }
    }
}

class AppState: ObservableObject {
    @Published var preferredColorScheme: ColorScheme? = nil
    @Published var isLoading = false
    @Published var error: Error?
    
    func showError(_ error: Error) {
        self.error = error
    }
    
    func clearError() {
        self.error = nil
    }
}
