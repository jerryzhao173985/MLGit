import SwiftUI

extension View {
    func errorAlert(error: Binding<Error?>, retry: (() -> Void)? = nil) -> some View {
        self.alert("Error", isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK") {
                error.wrappedValue = nil
            }
            
            if let retry = retry {
                Button("Retry") {
                    error.wrappedValue = nil
                    retry()
                }
            }
        } message: {
            if let error = error.wrappedValue {
                Text(error.friendlyMessage)
            }
        }
    }
    
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        
                        if let message = message {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    func refreshable(action: @escaping () async -> Void) -> some View {
        self.refreshable {
            await action()
        }
    }
}

extension Error {
    var friendlyMessage: String {
        if let networkError = self as? NetworkError {
            switch networkError {
            case .invalidURL:
                return "The requested URL is invalid. Please try again."
            case .noData:
                return "No data was received. Please check your connection."
            case .httpError(let code):
                switch code {
                case 404:
                    return "The requested resource was not found."
                case 500...599:
                    return "Server error. Please try again later."
                default:
                    return "Network error (code: \(code))"
                }
            case .decodingError(let message):
                return "Failed to process server response: \(message)"
            case .parsingError(let message):
                return "Failed to parse content: \(message)"
            case .unknown:
                return "An unexpected error occurred. Please try again."
            }
        } else if let parserError = self as? ParserError {
            switch parserError {
            case .invalidHTML:
                return "The server returned an unexpected response format."
            case .missingElement:
                return "Some content could not be loaded. Please try again."
            case .parsingFailed(let reason):
                return "Failed to load content: \(reason)"
            }
        } else {
            return self.localizedDescription
        }
    }
}

// Retry mechanism with exponential backoff
class RetryManager {
    private var retryCount = 0
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0
    
    func reset() {
        retryCount = 0
    }
    
    func shouldRetry() -> Bool {
        return retryCount < maxRetries
    }
    
    func incrementRetry() {
        retryCount += 1
    }
    
    var currentDelay: TimeInterval {
        return baseDelay * pow(2.0, Double(retryCount))
    }
    
    func performWithRetry<T>(operation: @escaping () async throws -> T) async throws -> T {
        reset()
        
        while true {
            do {
                let result = try await operation()
                reset()
                return result
            } catch {
                if shouldRetry() {
                    incrementRetry()
                    try await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                } else {
                    throw error
                }
            }
        }
    }
}