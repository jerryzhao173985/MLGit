import SwiftUI

struct LoadingStateView: View {
    let title: String
    let message: String?
    
    init(title: String = "Loading...", message: String? = nil) {
        self.title = title
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

struct LoadingSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<5) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                        .frame(maxWidth: .random(in: 0.5...0.8) * UIScreen.main.bounds.width)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .frame(maxWidth: .random(in: 0.3...0.6) * UIScreen.main.bounds.width)
                }
                .padding(.horizontal)
            }
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "arrow.clockwise")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

struct ErrorStateView: View {
    let error: Error
    let retry: (() -> Void)?
    
    var body: some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            title: "Something went wrong",
            message: errorMessage,
            actionTitle: retry != nil ? "Try Again" : nil,
            action: retry
        )
    }
    
    private var errorMessage: String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidURL:
                return "The requested URL is invalid."
            case .noData:
                return "No data was received from the server."
            case .httpError(let code):
                return "Server error: \(code)"
            case .decodingError(let message):
                return "Failed to decode response: \(message)"
            case .parsingError(let message):
                return "Failed to parse content: \(message)"
            case .unknown:
                return "An unknown error occurred."
            }
        } else if let parserError = error as? ParserError {
            switch parserError {
            case .invalidHTML:
                return "The server returned invalid HTML."
            case .missingElement(let selector):
                return "Required content not found: \(selector)"
            case .parsingFailed(let reason):
                return "Parsing failed: \(reason)"
            }
        } else {
            return error.localizedDescription
        }
    }
}

struct NoConnectionView: View {
    var body: some View {
        EmptyStateView(
            icon: "wifi.slash",
            title: "No Internet Connection",
            message: "Please check your connection and try again."
        )
    }
}

// Preview
struct LoadingStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingStateView(title: "Loading repositories...", message: "This may take a moment")
            
            LoadingSkeletonView()
            
            EmptyStateView(
                icon: "folder",
                title: "No Repositories",
                message: "There are no repositories to display.",
                actionTitle: "Refresh",
                action: {}
            )
            
            ErrorStateView(
                error: NetworkError.httpError(404),
                retry: {}
            )
            
            NoConnectionView()
        }
    }
}