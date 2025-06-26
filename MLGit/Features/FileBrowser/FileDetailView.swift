import Foundation
import SwiftUI

struct FileDetailView: View {
    let repositoryPath: String
    let filePath: String
    
    var body: some View {
        // Redirect to EnhancedFileDetailView which is the actual view being used
        EnhancedFileDetailView(
            repositoryPath: repositoryPath,
            filePath: filePath
        )
    }
}

struct FileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FileDetailView(
                repositoryPath: "tosa/reference_model.git",
                filePath: "README.md"
            )
        }
    }
}