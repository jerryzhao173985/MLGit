import Foundation
import SwiftUI
import WebKit
import GitHTMLParser
import Combine

struct AboutView: View {
    let repositoryPath: String
    @StateObject private var viewModel: AboutViewModel
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self._viewModel = StateObject(wrappedValue: AboutViewModel(repositoryPath: repositoryPath))
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.aboutContent == nil {
                LoadingStateView(title: "Loading README...")
            } else if let error = viewModel.error {
                ErrorStateView(error: error) {
                    Task {
                        await viewModel.loadAboutContent()
                    }
                }
            } else if let aboutContent = viewModel.aboutContent {
                VStack(alignment: .leading, spacing: 20) {
                    HTMLView(htmlContent: aboutContent.htmlContent)
                        .frame(minHeight: 300)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actions")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            Link(destination: URLBuilder.about(repositoryPath: repositoryPath)) {
                                Label("View on Web", systemImage: "safari")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            ShareLink(item: URLBuilder.about(repositoryPath: repositoryPath)) {
                                Label("Share Repository", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.secondary.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No README",
                    message: "This repository doesn't have a README file."
                )
            }
        }
        .refreshable {
            await viewModel.loadAboutContent()
        }
        .task {
            await viewModel.loadAboutContent()
        }
    }
}

struct HTMLView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let style = """
        <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            color: \(UIColor.label.hexString);
            background-color: transparent;
            margin: 0;
            padding: 0;
        }
        pre {
            background-color: \(UIColor.secondarySystemBackground.hexString);
            padding: 12px;
            border-radius: 8px;
            overflow-x: auto;
        }
        code {
            font-family: 'SF Mono', Monaco, monospace;
            font-size: 14px;
            background-color: \(UIColor.secondarySystemBackground.hexString);
            padding: 2px 4px;
            border-radius: 4px;
        }
        pre code {
            background-color: transparent;
            padding: 0;
        }
        a {
            color: \(UIColor.systemBlue.hexString);
            text-decoration: none;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 16px 0;
        }
        th, td {
            border: 1px solid \(UIColor.separator.hexString);
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: \(UIColor.secondarySystemBackground.hexString);
        }
        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
        }
        img {
            max-width: 100%;
            height: auto;
        }
        </style>
        """
        
        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no">
        \(style)
        </head>
        <body>
        \(htmlContent)
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: URL(string: "https://git.mlplatform.org"))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { height, _ in
                if let height = height as? CGFloat {
                    DispatchQueue.main.async {
                        webView.frame.size.height = height
                    }
                }
            }
        }
    }
}

@MainActor
class AboutViewModel: ObservableObject {
    @Published var aboutContent: AboutContent?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let repositoryPath: String
    private let gitService = GitService.shared
    
    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
    }
    
    func loadAboutContent() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            aboutContent = try await gitService.fetchAboutContent(repositoryPath: repositoryPath)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

extension UIColor {
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return String(format: "#%06x", rgb)
    }
}