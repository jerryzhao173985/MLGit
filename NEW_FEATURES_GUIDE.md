# MLGit iOS App - New Features Quick Reference Guide

## 🎯 How to Use the New Features

### 1. Loading Skeletons
Loading skeletons automatically appear when content is loading. No action needed!

**Where you'll see them:**
- Repository list (Explore tab)
- File browser (Code tab)
- Commit history (Commits tab)

### 2. Swipe Gestures

#### Swipe to Go Back
- **How**: Swipe from the left edge of the screen to the right
- **Where**: File detail views
- **Alternative**: Swipe anywhere on the screen (not just the edge)

#### Adding to Your Views:
```swift
YourView()
    .swipeToGoBack()
```

### 3. Haptic Feedback

Haptic feedback is automatic for these interactions:
- Tapping on repository rows
- Switching tabs
- Starring/unstarring repositories
- Navigating to commits
- Pull to refresh

#### Adding Haptic Feedback to New Features:

**For Buttons:**
```swift
Button("Action") {
    HapticManager.shared.mediumImpact()
    // Your action
}
```

**For List Rows:**
```swift
NavigationLink {
    // Destination
} label: {
    // Content
}
.listRowHaptic()
```

**For Success/Error:**
```swift
// Success
HapticManager.shared.notificationSuccess()

// Error
HapticManager.shared.notificationError()

// Warning
HapticManager.shared.notificationWarning()
```

### 4. Using the Enhanced Chunk Manager

The chunk manager automatically activates for files > 10KB. It:
- Loads content in 300-line chunks
- Caches only 10 chunks in memory
- Automatically evicts old chunks

**No configuration needed!**

### 5. Network Request Deduplication

Automatic - if multiple components request the same URL simultaneously, only one network request is made.

## 🔧 Developer Tips

### Creating New Skeleton Views
```swift
struct MySkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            // Your skeleton layout
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 20)
                .shimmer(isAnimating: isAnimating)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
```

### Adding Swipe Actions to Lists
```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .swipeActions {
                // Leading actions
                Button("Star") { }
            } trailing: {
                // Trailing actions
                Button("Delete") { }
            }
    }
}
```

### Safe Force Unwrapping Pattern
```swift
// ❌ Bad
let data = string.data(using: .utf8)!

// ✅ Good
guard let data = string.data(using: .utf8) else {
    print("Failed to encode string")
    return
}
```

### Memory-Conscious Task Blocks
```swift
// ❌ Bad
Task {
    self.property = value
}

// ✅ Good
Task { [weak self] in
    self?.property = value
}
```

## 📱 User Experience Guidelines

1. **Loading States**: Always show skeletons for lists, spinners for single items
2. **Haptic Feedback**: Use sparingly - only for significant interactions
3. **Swipe Gestures**: Keep consistent with iOS patterns
4. **Error Handling**: Always provide user-friendly error messages

## 🚀 Performance Best Practices

1. **Large Files**: Trust the chunk manager - it handles memory automatically
2. **Network Requests**: Don't worry about duplicates - deduplication is automatic
3. **Memory Leaks**: Always use `[weak self]` in closures and Task blocks
4. **Animations**: Keep them subtle and respect reduced motion settings

## 🐛 Debugging Tips

1. **Check Console**: Enhanced logging for file loading, caching, and network requests
2. **Memory Graph**: Use Xcode's memory graph to verify no retain cycles
3. **Network Inspector**: Verify request deduplication is working
4. **Haptic Testing**: Test on real device (simulator doesn't support haptics)

## 📝 Testing Checklist

- [ ] Loading skeletons appear and disappear smoothly
- [ ] Swipe gestures feel natural and responsive
- [ ] Haptic feedback is subtle but noticeable
- [ ] Large files load without memory warnings
- [ ] No duplicate network requests in logs
- [ ] No memory leaks in Instruments

Happy coding! 🎉