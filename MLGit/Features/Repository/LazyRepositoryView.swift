import SwiftUI

/// Wrapper to lazily create RepositoryView only when navigation occurs
struct LazyRepositoryView: View {
    let repositoryPath: String
    
    var body: some View {
        RepositoryView(repositoryPath: repositoryPath)
    }
}