import Foundation
import SwiftUI
import Combine

@main
struct MLGitApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(networkMonitor)
                .preferredColorScheme(appState.preferredColorScheme)
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
