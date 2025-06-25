import SwiftUI

struct TestEnhancementsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Implementations") {
                    NavigationLink("Test Enhanced Diff View") {
                        EnhancedDiffView(
                            repositoryPath: "tosa/reference_model.git",
                            commitSHA: "cd167baf693b155805622e340008388cc89f61b2"
                        )
                    }
                    
                    NavigationLink("Test Enhanced File View (README)") {
                        EnhancedFileDetailView(
                            repositoryPath: "tosa/reference_model.git",
                            filePath: "README.md"
                        )
                    }
                    
                    NavigationLink("Test Enhanced File View (Code)") {
                        EnhancedFileDetailView(
                            repositoryPath: "tosa/reference_model.git",
                            filePath: "reference_model_src/ops/ewise_unary.cc"
                        )
                    }
                }
                
                Section("New Enhanced Components") {
                    NavigationLink("Test Advanced Diff View") {
                        AdvancedDiffView(
                            repositoryPath: "tosa/reference_model.git",
                            commitSHA: "cd167baf693b155805622e340008388cc89f61b2"
                        )
                    }
                    
                    NavigationLink("Test Enhanced Markdown") {
                        EnhancedMarkdownView(
                            content: sampleMarkdown
                        )
                        .navigationTitle("Enhanced Markdown")
                    }
                    
                    NavigationLink("Test Runestone Code View") {
                        RunestoneCodeViewWrapper(
                            content: sampleSwiftCode,
                            language: "swift",
                            fileName: "SampleCode.swift"
                        )
                        .navigationTitle("Runestone Code View")
                    }
                    
                    NavigationLink("Test Theme System") {
                        ThemeTestView()
                    }
                }
                
                Section("Test Sample Content") {
                    NavigationLink("Test Markdown Rendering") {
                        MarkdownView(
                            content: sampleMarkdown,
                            fontSize: 16
                        )
                    }
                    
                    NavigationLink("Test Patch Rendering") {
                        ScrollView {
                            GitPatchView(
                                patch: samplePatch,
                                fontSize: 13,
                                showLineNumbers: true,
                                splitView: false
                            )
                        }
                    }
                }
                
                Section("Debug Tools") {
                    NavigationLink("Debug File View (README)") {
                        DebugFileView(
                            repositoryPath: "tosa/reference_model.git",
                            filePath: "README.md"
                        )
                    }
                    
                    NavigationLink("Debug File View (Code)") {
                        DebugFileView(
                            repositoryPath: "tosa/reference_model.git",
                            filePath: "reference_model_src/ops/ewise_unary.cc"
                        )
                    }
                    
                    NavigationLink("Debug About View") {
                        AboutView(repositoryPath: "tosa/reference_model.git")
                    }
                }
            }
            .navigationTitle("Test Enhancements")
        }
        .environmentObject(themeManager)
        .environment(\.codeTheme, themeManager.currentTheme)
    }
    
    // Sample Swift code for testing
    private let sampleSwiftCode = """
    import SwiftUI
    import Combine
    
    /// A sample view model demonstrating various Swift features
    @MainActor
    class SampleViewModel: ObservableObject {
        @Published var items: [Item] = []
        @Published var isLoading = false
        @Published var error: Error?
        
        private var cancellables = Set<AnyCancellable>()
        private let service: DataService
        
        init(service: DataService = .shared) {
            self.service = service
            setupBindings()
        }
        
        private func setupBindings() {
            $items
                .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
                .sink { [weak self] items in
                    self?.processItems(items)
                }
                .store(in: &cancellables)
        }
        
        func loadData() async {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let response = try await service.fetchItems()
                await MainActor.run {
                    self.items = response.items
                }
            } catch {
                self.error = error
            }
        }
        
        private func processItems(_ items: [Item]) {
            // Complex processing logic
            let filtered = items.filter { $0.isValid }
            let sorted = filtered.sorted { $0.priority > $1.priority }
            print("Processed \\(sorted.count) items")
        }
    }
    
    struct Item: Identifiable {
        let id = UUID()
        var name: String
        var priority: Int
        var isValid: Bool
    }
    """
}

private let sampleMarkdown = """
# TOSA Reference Model

This is a **test** of the _markdown_ rendering.

## Features

- Bullet point 1
- Bullet point 2
  - Nested item
- Bullet point 3

### Code Example

```swift
func hello(name: String) {
    print("Hello, \\(name)!")
}
```

### Table Example

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| Data 4   | Data 5   | Data 6   |

> This is a blockquote with some important information.

Visit [GitHub](https://github.com) for more information.
"""

private let samplePatch = """
From cd167baf693b155805622e340008388cc89f61b2 Mon Sep 17 00:00:00 2001
From: Philip Wilkinson <philip.wilkinson@arm.com>
Date: Thu, 19 Jun 2025 16:01:39 +0100
Subject: Add Windows build instructions to README

Note does not cover test commands

Signed-off-by: Philip Wilkinson <philip.wilkinson@arm.com>
Change-Id: Ib1cb340290cf5c663e00185aaaaad68388bb4477
---
 README.md | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/README.md b/README.md
index 27475e78d..a3c4f1e2a 100644
--- a/README.md
+++ b/README.md
@@ -53,8 +53,9 @@ The *TOSA Reference Model* and testing suite requires the following tools:
 | GNU Make  | 4.1 or later      |                                           |
 | GCC       | 9.4.0 or later    | with C++17 support                        |
 | Clang C++ | 14 or later       | tested with clang-14 (with C++17 support) |
+| MSVC      |                   | tested with 19.41.34123.0                 |
 
-==Either GCC or Clang can be used==
+==On Linux, Either GCC or Clang can be used==
 
 The model includes the following dependencies:
 
@@ -104,6 +105,7 @@ Where `VERSION` can be for example: `v0.23` or `v0.23.0`
 
 The *TOSA Reference Model* build can be prepared by creating makefiles using CMake:
 
+Linux
 ``` bash
 mkdir -p build
 cd build
"""