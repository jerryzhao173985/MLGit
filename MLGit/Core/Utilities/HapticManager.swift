import UIKit

/// Manages haptic feedback throughout the app
final class HapticManager {
    static let shared = HapticManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for lower latency
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    // MARK: - Impact Feedback
    
    /// Light impact for subtle interactions (e.g., tab selection)
    func lightImpact() {
        impactLight.impactOccurred()
        impactLight.prepare() // Re-prepare for next use
    }
    
    /// Medium impact for standard interactions (e.g., button taps)
    func mediumImpact() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }
    
    /// Heavy impact for significant actions (e.g., deletions)
    func heavyImpact() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed feedback (e.g., picker selection, toggle)
    func selectionChanged() {
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification (e.g., task completed)
    func notificationSuccess() {
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }
    
    /// Warning notification (e.g., approaching limit)
    func notificationWarning() {
        notificationFeedback.notificationOccurred(.warning)
        notificationFeedback.prepare()
    }
    
    /// Error notification (e.g., action failed)
    func notificationError() {
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }
    
    // MARK: - Custom Patterns
    
    /// Double tap pattern for confirmations
    func doubleTap() {
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.lightImpact()
        }
    }
    
    /// Success pattern (light tap followed by success notification)
    func successPattern() {
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notificationSuccess()
        }
    }
    
    /// Error pattern (heavy impact followed by error notification)
    func errorPattern() {
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.notificationError()
        }
    }
}

// MARK: - SwiftUI View Extensions
import SwiftUI

extension View {
    /// Adds haptic feedback when the view is tapped
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            switch style {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            default:
                HapticManager.shared.mediumImpact()
            }
        }
    }
    
    /// Adds haptic feedback when a button is pressed
    func hapticButton() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.mediumImpact()
                }
        )
    }
    
    /// Adds haptic feedback when appearing
    func hapticOnAppear(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onAppear {
            switch style {
            case .light:
                HapticManager.shared.lightImpact()
            case .medium:
                HapticManager.shared.mediumImpact()
            case .heavy:
                HapticManager.shared.heavyImpact()
            default:
                HapticManager.shared.lightImpact()
            }
        }
    }
    
    /// Adds haptic feedback for toggle changes
    func hapticToggle() -> some View {
        self.onChange(of: true) { _, _ in
            HapticManager.shared.selectionChanged()
        }
    }
}

// MARK: - Button Style with Haptic Feedback
struct HapticButtonStyle: ButtonStyle {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    
    init(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        self.style = style
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    switch style {
                    case .light:
                        HapticManager.shared.lightImpact()
                    case .medium:
                        HapticManager.shared.mediumImpact()
                    case .heavy:
                        HapticManager.shared.heavyImpact()
                    default:
                        HapticManager.shared.mediumImpact()
                    }
                }
            }
    }
}

// MARK: - List Row Haptic Modifier
struct ListRowHapticModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.shared.lightImpact()
            }
    }
}

extension View {
    func listRowHaptic() -> some View {
        modifier(ListRowHapticModifier())
    }
}

// MARK: - Tab Selection Haptic
struct TabSelectionHapticModifier: ViewModifier {
    let selection: Int
    
    func body(content: Content) -> some View {
        content
            .onChange(of: selection) { _, _ in
                HapticManager.shared.selectionChanged()
            }
    }
}

extension View {
    func tabSelectionHaptic(selection: Int) -> some View {
        modifier(TabSelectionHapticModifier(selection: selection))
    }
}

// MARK: - Refresh Control Haptic
struct RefreshHapticModifier: ViewModifier {
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                HapticManager.shared.mediumImpact()
                await action()
                HapticManager.shared.notificationSuccess()
            }
    }
}

extension View {
    func refreshableWithHaptic(action: @escaping () async -> Void) -> some View {
        modifier(RefreshHapticModifier(action: action))
    }
}