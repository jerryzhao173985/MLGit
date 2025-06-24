import Foundation
import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showingAppError = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "square.grid.2x2")
            }
            .tag(0)
            
            NavigationView {
                StarredView()
            }
            .tabItem {
                Label("Starred", systemImage: "star")
            }
            .tag(1)
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .onReceive(appState.$error) { error in
            showingAppError = error != nil
        }
        .alert("Error", isPresented: $showingAppError) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(appState.error?.localizedDescription ?? "An error occurred")
        }
    }
}

