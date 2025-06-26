import SwiftUI
import Combine

/// Enhanced directory view with proper navigation and caching
struct EnhancedDirectoryView: View {
    let repositoryPath: String
    
    @StateObject private var viewModel: EnhancedDirectoryViewModel
    @StateObject private var navigationState = NavigationStateManager.shared
    @StateObject private var directoryCache = DirectoryCache.shared
    
    @State private var showingError = false
    @State private var selectedFile: FileNode?
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self._viewModel = StateObject(wrappedValue: EnhancedDirectoryViewModel(repositoryPath: repositoryPath))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb navigation
            if !navigationPath.isEmpty {
                BreadcrumbNavigation(
                    repository: repositoryPath,
                    path: navigationPath,
                    onNavigate: { level in
                        navigateToLevel(level)
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
            }
            
            // File list
            List {
                // Up navigation
                if !navigationPath.isEmpty {
                    Button(action: navigateUp) {
                        HStack {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.blue)
                            Text("..")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                // Show cached content immediately
                if let cachedFiles = viewModel.cachedFiles, !cachedFiles.isEmpty {
                    ForEach(cachedFiles) { file in
                        FileRow(
                            file: file,
                            isLoading: viewModel.isLoading,
                            onTap: {
                                handleFileTap(file)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                } else if viewModel.isLoading && viewModel.files.isEmpty {
                    // Show skeleton while loading
                    ForEach(0..<10, id: \.self) { _ in
                        FileListSkeletonRow()
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                } else if !viewModel.files.isEmpty {
                    // Show fetched files
                    ForEach(viewModel.files) { file in
                        FileRow(
                            file: file,
                            isLoading: false,
                            onTap: {
                                handleFileTap(file)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                } else if !viewModel.isLoading {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No files in this directory")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                await viewModel.refreshFiles(forceNetwork: true)
            }
        }
        .navigationTitle(currentDirectoryName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedFile) { file in
            NavigationView {
                OptimizedFileDetailView(
                    repositoryPath: repositoryPath,
                    filePath: currentPath.isEmpty ? file.path : "\(currentPath)/\(file.path)"
                )
            }
        }
        .task {
            await viewModel.loadFiles(path: currentPath)
        }
        .onChange(of: currentPath) { newPath in
            Task {
                await viewModel.loadFiles(path: newPath)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
        .onReceive(viewModel.$error) { error in
            showingError = error != nil
        }
    }
    
    // MARK: - Computed Properties
    
    private var navigationPath: [NavigationStateManager.NavigationPathItem] {
        navigationState.navigationPath(for: repositoryPath)
    }
    
    private var currentPath: String {
        navigationState.currentPath(for: repositoryPath)
    }
    
    private var currentDirectoryName: String {
        navigationPath.last?.name ?? "Code"
    }
    
    // MARK: - Navigation Methods
    
    private func handleFileTap(_ file: FileNode) {
        HapticManager.shared.lightImpact()
        
        if file.isDirectory {
            // Navigate to directory
            navigationState.navigateToDirectory(
                in: repositoryPath,
                directory: file.name,
                path: file.path
            )
        } else {
            // Navigate to file
            selectedFile = file
        }
    }
    
    private func navigateUp() {
        HapticManager.shared.lightImpact()
        _ = navigationState.navigateUp(in: repositoryPath)
    }
    
    private func navigateToLevel(_ level: Int) {
        HapticManager.shared.lightImpact()
        _ = navigationState.navigateToPathLevel(in: repositoryPath, level: level)
    }
}

// MARK: - File Row Component
struct FileRow: View {
    let file: FileNode
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: file.icon)
                    .foregroundColor(file.isDirectory ? .blue : .secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    if let size = file.size, !file.isDirectory {
                        Text(formatBytes(size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if file.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Breadcrumb Navigation
struct BreadcrumbNavigation: View {
    let repository: String
    let path: [NavigationStateManager.NavigationPathItem]
    let onNavigate: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Root
                Button(action: { onNavigate(-1) }) {
                    Text("Root")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                ForEach(Array(path.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Button(action: { onNavigate(index) }) {
                            Text(item.name)
                                .font(.caption)
                                .foregroundColor(index == path.count - 1 ? .primary : .blue)
                        }
                        .disabled(index == path.count - 1)
                    }
                }
            }
        }
    }
}

// MARK: - Skeleton Row
struct FileListSkeletonRow: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: CGFloat.random(in: 100...200), height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: CGFloat.random(in: 50...100), height: 12)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Model
@MainActor
class EnhancedDirectoryViewModel: ObservableObject {
    @Published var files: [FileNode] = []
    @Published var cachedFiles: [FileNode]?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let gitService = GitService.shared
    private let directoryCache = DirectoryCache.shared
    private var cancellables = Set<AnyCancellable>()
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
    }
    
    func loadFiles(path: String? = nil) async {
        let actualPath = path ?? ""
        
        // Show cached content immediately
        if let cached = await directoryCache.getCachedDirectory(
            repository: repositoryPath,
            path: actualPath
        ) {
            self.cachedFiles = cached
        }
        
        // Check if already loading
        if directoryCache.isLoading(repository: repositoryPath, path: actualPath) {
            return
        }
        
        isLoading = true
        directoryCache.setLoading(repository: repositoryPath, path: actualPath, isLoading: true)
        
        defer {
            isLoading = false
            directoryCache.setLoading(repository: repositoryPath, path: actualPath, isLoading: false)
        }
        
        do {
            let fetchedFiles = try await gitService.fetchTree(
                repositoryPath: repositoryPath,
                path: actualPath,
                sha: nil
            )
            
            // Sort files
            let sortedFiles = fetchedFiles.sorted { file1, file2 in
                if file1.isDirectory != file2.isDirectory {
                    return file1.isDirectory
                }
                return file1.name.localizedCaseInsensitiveCompare(file2.name) == .orderedAscending
            }
            
            self.files = sortedFiles
            self.cachedFiles = nil // Clear cached files once real data is loaded
            
            // Cache the result
            await directoryCache.cacheDirectory(
                repository: repositoryPath,
                path: actualPath,
                files: sortedFiles
            )
            
            // Prefetch subdirectories
            await directoryCache.prefetchSubdirectories(
                repository: repositoryPath,
                path: actualPath,
                files: sortedFiles,
                gitService: gitService
            )
        } catch {
            self.error = error
            // Keep showing cached content on error
        }
    }
    
    func refreshFiles(forceNetwork: Bool = false) async {
        if forceNetwork {
            directoryCache.clearCache(for: repositoryPath)
        }
        await loadFiles(path: NavigationStateManager.shared.currentPath(for: repositoryPath))
    }
}