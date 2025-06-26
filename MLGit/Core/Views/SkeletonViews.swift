import SwiftUI

// MARK: - Repository List Skeleton
struct RepositoryListSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<6) { _ in
                RepositorySkeletonRow()
                    .shimmer(isAnimating: isAnimating)
                Divider()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct RepositorySkeletonRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                // Repository name
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: CGFloat.random(in: 120...200), height: 16)
                
                // Description
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: CGFloat.random(in: 200...280), height: 14)
                
                // Meta info
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 60, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 80, height: 12)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - File List Skeleton
struct FileListSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<10) { index in
                FileSkeletonRow(isDirectory: index % 3 == 0)
                    .shimmer(isAnimating: isAnimating)
                
                if index < 9 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct FileSkeletonRow: View {
    let isDirectory: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // File/Folder icon
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                // Filename
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: CGFloat.random(in: 100...180), height: 14)
                
                // File size (only for files)
                if !isDirectory {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 11)
                }
            }
            
            Spacer()
            
            // Chevron for directories
            if isDirectory {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 8, height: 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Commit List Skeleton
struct CommitListSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8) { _ in
                CommitSkeletonRow()
                    .shimmer(isAnimating: isAnimating)
                Divider()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct CommitSkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Commit message
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: CGFloat.random(in: 200...300), height: 16)
            
            HStack(spacing: 12) {
                // Author avatar
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 20, height: 20)
                
                // Author name
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
                
                // Commit SHA
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 12)
                
                Spacer()
                
                // Date
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 40, height: 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Code View Skeleton
struct CodeViewSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<20) { lineNumber in
                    HStack(spacing: 16) {
                        // Line number
                        Text("\(lineNumber + 1)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.5))
                            .frame(width: 30, alignment: .trailing)
                        
                        // Code line
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: randomCodeLineWidth(), height: 14)
                            .shimmer(isAnimating: isAnimating)
                        
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    private func randomCodeLineWidth() -> CGFloat {
        let widths: [CGFloat] = [80, 120, 160, 200, 240, 280, 320, 100, 140, 180]
        return widths.randomElement() ?? 160
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isAnimating {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.3)
                        .animation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    }
                }
            )
            .clipped()
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

// MARK: - Loading Card Skeleton
struct LoadingCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .frame(maxWidth: .infinity)
            
            // Content lines
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(maxWidth: CGFloat.random(in: 0.6...0.9) * UIScreen.main.bounds.width)
            }
            
            // Footer
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 14)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 14)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .shimmer(isAnimating: isAnimating)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Previews
struct SkeletonViews_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Repository List Skeleton")
                        .font(.headline)
                    RepositoryListSkeletonView()
                    
                    Divider()
                    
                    Text("File List Skeleton")
                        .font(.headline)
                    FileListSkeletonView()
                    
                    Divider()
                    
                    Text("Commit List Skeleton")
                        .font(.headline)
                    CommitListSkeletonView()
                    
                    Divider()
                    
                    Text("Code View Skeleton")
                        .font(.headline)
                    CodeViewSkeletonView()
                        .frame(height: 300)
                    
                    Divider()
                    
                    Text("Loading Card")
                        .font(.headline)
                    LoadingCardSkeleton()
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Skeleton Views")
        }
    }
}