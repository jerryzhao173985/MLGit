import SwiftUI

struct ImageFileView: View {
    let content: FileContent
    let filePath: String
    
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading image...")
                } else if let error = error {
                    ContentUnavailableView(
                        "Unable to Display Image",
                        systemImage: "photo.badge.exclamationmark",
                        description: Text(error)
                    )
                } else if let image = image {
                    imageContent(image: image, geometry: geometry)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if image != nil {
                    imageToolbar
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    @ViewBuilder
    private func imageContent(image: UIImage, geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Image info bar
            HStack {
                Label("\(Int(image.size.width)) × \(Int(image.size.height))", systemImage: "square.dashed")
                    .font(.caption)
                
                Spacer()
                
                Text(formatBytes(content.size))
                    .font(.caption)
                
                Spacer()
                
                Text("\(Int(scale * 100))%")
                    .font(.caption.monospacedDigit())
            }
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            
            // Zoomable image
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { value in
                                lastScale = scale
                                withAnimation(.spring()) {
                                    scale = min(max(scale, 0.5), 5.0)
                                }
                                lastScale = scale
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .frame(
                        width: geometry.size.width * scale,
                        height: geometry.size.height * scale
                    )
            }
            .background(
                // Checkerboard pattern for transparent images
                CheckerboardPattern()
                    .opacity(0.1)
            )
        }
    }
    
    @ViewBuilder
    private var imageToolbar: some View {
        Menu {
            Section("Zoom") {
                Button("Fit to Screen") {
                    withAnimation {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
                
                Button("Zoom In") {
                    withAnimation {
                        scale = min(scale * 1.5, 5.0)
                        lastScale = scale
                    }
                }
                
                Button("Zoom Out") {
                    withAnimation {
                        scale = max(scale / 1.5, 0.5)
                        lastScale = scale
                    }
                }
            }
            
            Section {
                if let image = image {
                    ShareLink(item: Image(uiImage: image), preview: SharePreview(filePath, image: Image(uiImage: image))) {
                        Label("Share Image", systemImage: "square.and.arrow.up")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    private func loadImage() {
        isLoading = true
        error = nil
        
        // Try to create image from base64 or data
        if let data = Data(base64Encoded: content.content) {
            image = UIImage(data: data)
        } else if let data = content.content.data(using: .utf8) {
            image = UIImage(data: data)
        } else {
            // If content is binary and we have the raw data
            error = "Unable to decode image data"
        }
        
        isLoading = false
        
        if image == nil && error == nil {
            error = "Invalid image format"
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Checkerboard Pattern

struct CheckerboardPattern: View {
    var body: some View {
        GeometryReader { geometry in
            let size: CGFloat = 20
            let rows = Int(geometry.size.height / size) + 1
            let columns = Int(geometry.size.width / size) + 1
            
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { column in
                    Rectangle()
                        .fill((row + column) % 2 == 0 ? Color.gray.opacity(0.3) : Color.clear)
                        .frame(width: size, height: size)
                        .position(
                            x: CGFloat(column) * size + size/2,
                            y: CGFloat(row) * size + size/2
                        )
                }
            }
        }
    }
}