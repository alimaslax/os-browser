import SwiftUI

struct CommandPalette: View {
    @ObservedObject private var keyboardHandler = KeyboardShortcutHandler.shared
    @ObservedObject private var providerManager = AIProviderManager.shared
    @State private var query: String = ""
    @State private var selectionIndex: Int = 0

    // Arc-style data (mocked for visual replication + existing functional items)
    private var filteredItems: [PaletteItem] {
        let base: [PaletteItem] = [
             // Promoted Actions (like "Contact the Team")
            .action(title: "Contact the Team", icon: "bubble.left.and.bubble.right.fill", isPromoted: true) {
                // Placeholder action
                 NotificationCenter.default.post(name: .showSettingsRequested, object: nil)
            },
            
            // Standard Actions
            .action(title: "New Tab", icon: "plus") {
                NotificationCenter.default.post(name: .newTabRequested, object: nil)
            },
             .action(title: "Google", icon: "magnifyingglass") {
                 // Trigger search logic
                 // In a real implementation this would navigate
            },
             .action(title: "Search for \"" + (query.isEmpty ? "..." : query) + "\"", icon: "magnifyingglass") {
                 // Search action
             },
             
             // Existing functional items
            .action(title: "TL;DR this page", icon: "text.alignleft") {
                NotificationCenter.default.post(name: .performTLDRRequested, object: nil)
            },
            .action(title: "Ask about this page…", icon: "questionmark.bubble") {
                NotificationCenter.default.post(name: .performAskRequested, object: nil)
            },
            .action(title: "Toggle AI Sidebar", icon: "sidebar.right") {
                NotificationCenter.default.post(name: .toggleAISidebar, object: nil)
            },
            .action(title: "Focus Address Bar", icon: "magnifyingglass") {
                NotificationCenter.default.post(name: .focusAddressBarRequested, object: nil)
            },
            .action(title: "Preferences", icon: "gear") {
                NotificationCenter.default.post(name: .showSettingsRequested, object: nil)
            }
        ]

        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return base
        }

        let lower = query.lowercased()
        return base.filter { 
            // Always show search action if typing
            if ($0.title.starts(with: "Search for")) { return true }
            return $0.title.lowercased().contains(lower) 
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Input Area
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search or Enter URL...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white) // Dark mode assumed
                    .onSubmit(executeSelected)
                    .padding(.vertical, 16)
                
                Image(systemName: "info.circle")
                     .font(.system(size: 16))
                     .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 20)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Results List
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(filteredItems.enumerated()), id: \.offset) { index, item in
                        PaletteRow(item: item, isSelected: index == selectionIndex)
                            .onTapGesture {
                                item.handler()
                                hide()
                            }
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 400) // Limit height
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95)) // Dark background
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
             //   .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
        )
        .frame(width: 600) // Fixed width like Arc
        .onExitCommand { hide() }
        .onAppear { selectionIndex = 0 }
        .onReceive(NotificationCenter.default.publisher(for: .showCommandPaletteRequested)) { _ in
            selectionIndex = 0
            query = ""
        }
        .onKeyPress(.downArrow) {
            incrementSelection()
            return .handled
        }
        .onKeyPress(.upArrow) {
            decrementSelection()
            return .handled
        }
        .onKeyPress(.return) {
            executeSelected()
            return .handled
        }
        // Force dark mode for Arc look
        .environment(\.colorScheme, .dark)
    }

    private func hide() {
        NotificationCenter.default.post(name: .hideCommandPaletteRequested, object: nil)
    }

    private func incrementSelection() {
        selectionIndex = min(selectionIndex + 1, max(filteredItems.count - 1, 0))
    }

    private func decrementSelection() {
        selectionIndex = max(selectionIndex - 1, 0)
    }

    private func executeSelected() {
        guard !filteredItems.isEmpty else { return }
        filteredItems[selectionIndex].handler()
        hide()
    }
}

// Subview for a single row
private struct PaletteRow: View {
    let item: PaletteItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
             if item.isPromoted {
                 // Special Promoted Style (Blue Button)
                 HStack {
                     Image(systemName: item.icon)
                     Text(item.title)
                         .fontWeight(.medium)
                 }
                 .padding(.vertical, 10)
                 .frame(maxWidth: .infinity, alignment: .leading)
                 .padding(.horizontal, 12)
                 .background(Color.blue)
                 .foregroundColor(.white)
                 .cornerRadius(8)
             } else {
                 // Standard Row
                 Image(systemName: item.icon)
                     .font(.system(size: 14))
                     .foregroundColor(.secondary)
                     .frame(width: 20)
                 
                 Text(item.title)
                     .font(.system(size: 14))
                     .foregroundColor(.primary)
                 
                 Spacer()
                 
                 // Optional helper text or shortcut hint could go here
             }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, item.isPromoted ? 0 : 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected && !item.isPromoted ? Color.white.opacity(0.1) : Color.clear)
        )
        // Add subtle border to selected item if needed, but Arc usually just highlights background
    }
}

private enum PaletteItem {
    case action(title: String, icon: String, isPromoted: Bool = false, handler: () -> Void)

    var title: String {
        switch self {
        case let .action(title, _, _, _): return title
        }
    }

    var icon: String {
        switch self {
        case let .action(_, icon, _, _): return icon
        }
    }
    
    var isPromoted: Bool {
        switch self {
        case let .action(_, _, isPromoted, _): return isPromoted
        }
    }

    var handler: () -> Void {
        switch self {
        case let .action(_, _, _, handler): return handler
        }
    }
}
