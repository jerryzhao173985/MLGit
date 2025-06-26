import SwiftUI

// MARK: - Swipe to Go Back Modifier
struct SwipeBackModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @State private var dragAmount = CGSize.zero
    @State private var isDragging = false
    
    private let threshold: CGFloat = 100
    private let maxDrag: CGFloat = UIScreen.main.bounds.width * 0.4
    
    func body(content: Content) -> some View {
        content
            .offset(x: min(dragAmount.width, maxDrag))
            .opacity(isDragging ? 0.9 : 1.0)
            .animation(.interactiveSpring(), value: dragAmount)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow right swipe (positive width)
                        if value.translation.width > 0 {
                            isDragging = true
                            dragAmount = value.translation
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        // If dragged more than threshold, dismiss the view
                        if value.translation.width > threshold &&
                           value.predictedEndTranslation.width > threshold * 1.5 {
                            dismiss()
                        } else {
                            // Snap back to original position
                            withAnimation(.spring()) {
                                dragAmount = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                // Add edge pan gesture for iOS-like behavior
                DragGesture()
                    .onChanged { value in
                        // Only respond to edge swipes (within 20 points of left edge)
                        if value.startLocation.x < 20 && value.translation.width > 0 {
                            isDragging = true
                            dragAmount = value.translation
                        }
                    }
            )
    }
}

// MARK: - Swipe Actions for List Rows
struct SwipeActionsModifier<LeadingActions: View, TrailingActions: View>: ViewModifier {
    @ViewBuilder let leadingActions: () -> LeadingActions
    @ViewBuilder let trailingActions: () -> TrailingActions
    
    @State private var offset: CGFloat = 0
    @State private var initialOffset: CGFloat = 0
    @State private var isShowingLeading = false
    @State private var isShowingTrailing = false
    
    private let actionWidth: CGFloat = 80
    
    func body(content: Content) -> some View {
        ZStack {
            // Background actions
            HStack {
                if isShowingLeading {
                    leadingActions()
                        .frame(width: abs(offset))
                }
                
                Spacer()
                
                if isShowingTrailing {
                    trailingActions()
                        .frame(width: abs(offset))
                }
            }
            
            // Main content
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newOffset = initialOffset + value.translation.width
                            
                            // Limit the offset
                            if newOffset > 0 {
                                // Swiping right - show leading actions
                                offset = min(newOffset, actionWidth)
                                isShowingLeading = true
                                isShowingTrailing = false
                            } else {
                                // Swiping left - show trailing actions
                                offset = max(newOffset, -actionWidth)
                                isShowingLeading = false
                                isShowingTrailing = true
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring()) {
                                // Snap to action width or back to center
                                if abs(offset) > actionWidth / 2 {
                                    offset = offset > 0 ? actionWidth : -actionWidth
                                    initialOffset = offset
                                } else {
                                    offset = 0
                                    initialOffset = 0
                                    isShowingLeading = false
                                    isShowingTrailing = false
                                }
                            }
                        }
                )
        }
    }
}

// MARK: - Pull to Refresh with Haptic Feedback
struct PullToRefreshModifier: ViewModifier {
    let action: () async -> Void
    @State private var isRefreshing = false
    @State private var pullProgress: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                // Add haptic feedback when refresh triggers
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
                
                await action()
            }
    }
}

// MARK: - Convenience Extensions
extension View {
    /// Adds swipe-to-go-back gesture to the view
    func swipeToGoBack() -> some View {
        modifier(SwipeBackModifier())
    }
    
    /// Adds swipe actions to a list row
    func swipeActions<Leading: View, Trailing: View>(
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) -> some View {
        modifier(SwipeActionsModifier(
            leadingActions: leading,
            trailingActions: trailing
        ))
    }
    
    /// Adds pull to refresh with haptic feedback
    func pullToRefreshWithHaptic(action: @escaping () async -> Void) -> some View {
        modifier(PullToRefreshModifier(action: action))
    }
}

// MARK: - Navigation Gesture Handler
struct NavigationGestureHandler: ViewModifier {
    @State private var navigationPath = NavigationPath()
    
    func body(content: Content) -> some View {
        NavigationStack(path: $navigationPath) {
            content
                .toolbar {
                    if !navigationPath.isEmpty {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                // Add haptic feedback for back button
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                navigationPath.removeLast()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                            }
                        }
                    }
                }
        }
        .environment(\.navigationPath, $navigationPath)
    }
}

// MARK: - Environment Values for Navigation
private struct NavigationPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath>? = nil
}

extension EnvironmentValues {
    var navigationPath: Binding<NavigationPath>? {
        get { self[NavigationPathKey.self] }
        set { self[NavigationPathKey.self] = newValue }
    }
}

// MARK: - Example Usage
struct SwipeGestureExample: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(0..<10) { index in
                    Text("Item \(index)")
                        .swipeActions {
                            // Leading actions
                            Button(action: {}) {
                                Label("Star", systemImage: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        } trailing: {
                            // Trailing actions
                            Button(action: {}) {
                                Label("Delete", systemImage: "trash.fill")
                                    .foregroundColor(.red)
                            }
                        }
                }
            }
            .navigationTitle("Swipe Actions")
        }
    }
}