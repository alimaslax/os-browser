import SwiftUI

struct SidebarTabView: View {
    @ObservedObject var tabManager: TabManager
    @State private var draggedTab: Web.Tab?
    @State private var hoveredTab: Web.Tab?
    @State private var dropTargetIndex: Int?
    @State private var isDragging: Bool = false
    @State private var isValidDropTarget: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Window controls spacer (traffic lights)
            Color.clear.frame(height: 38)
            
            // Integrated URL Bar & Navigation Area
            VStack(spacing: 12) {
                // Main URL Bar
                URLBar(
                    tabID: tabManager.activeTab?.id ?? UUID(),
                    themeColor: tabManager.activeTab?.themeColor,
                    mixedContentStatus: nil, // Add this if available
                    onSubmit: { urlString in
                        if let url = URL(string: urlString) {
                            if let activeTab = tabManager.activeTab {
                                activeTab.navigate(to: url)
                            } else {
                                tabManager.createNewTab(url: url)
                            }
                        }
                    },
                    isSidebarMode: true
                )
                .padding(.horizontal, 12)
                
                // Navigation Controls (Back/Forward/Reload) - Compact
                HStack(spacing: 20) {
                    if let activeTab = tabManager.activeTab {
                        Button(action: { activeTab.goBack() }) {
                             Image(systemName: "chevron.left")
                                 .font(.system(size: 14, weight: .medium))
                                 .foregroundColor(activeTab.canGoBack ? .white : .white.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(!activeTab.canGoBack)
                        
                        Button(action: { activeTab.goForward() }) {
                             Image(systemName: "chevron.right")
                                 .font(.system(size: 14, weight: .medium))
                                 .foregroundColor(activeTab.canGoForward ? .white : .white.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(!activeTab.canGoForward)
                        
                        Spacer()
                        
                        Button(action: { activeTab.reload() }) {
                             Image(systemName: "arrow.clockwise")
                                 .font(.system(size: 14, weight: .medium))
                                 .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
            
            // Centered "New Tab" button - Arc Style (Large Plus)
            newTabButton
                .padding(.bottom, 16)
             
            // Tab list with custom scrolling
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(Array(tabManager.tabs.enumerated()), id: \.element.id) { index, tab in
                        SidebarTabItem(
                            tab: tab,
                            isActive: tab.id == tabManager.activeTab?.id,
                            isHovered: hoveredTab?.id == tab.id,
                            isDragging: isDragging && draggedTab?.id == tab.id,
                            tabManager: tabManager
                        ) {
                            tabManager.setActiveTab(tab)
                        }
                        .scaleEffect(isDragging && draggedTab?.id == tab.id ? 1.02 : 1.0)
                        .opacity(isDragging && draggedTab?.id == tab.id ? 0.9 : 1.0)
                        .zIndex(isDragging && draggedTab?.id == tab.id ? 1000 : 0)
                        .overlay(
                            // Drop zone indicator - top edge
                            Rectangle()
                                .fill(isValidDropTarget ? Color.accentColor : Color.red)
                                .frame(height: 2)
                                .opacity(dropTargetIndex == index && isDragging ? 0.8 : 0.0)
                                .offset(y: -22) // Adjusted for tab height
                                .animation(.easeInOut(duration: 0.2), value: dropTargetIndex)
                        )
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredTab = hovering ? tab : nil
                            }
                        }
                        .contextMenu {
                            TabContextMenu(tab: tab, tabManager: tabManager)
                        }
                        .draggable(tab) {
                            SidebarTabPreview(tab: tab, isDragging: true)
                        }
                        .onDrag {
                            isDragging = true
                            draggedTab = tab
                            return NSItemProvider()
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            
            Spacer()
            
            // Bottom section actions (Profiles, Settings, Library)
            HStack(spacing: 20) {
                 Button(action: {
                     // Library / Archive
                  }) {
                      Image(systemName: "archivebox")
                          .font(.system(size: 16))
                          .foregroundColor(.white.opacity(0.6))
                  }
                  .buttonStyle(.plain)
                  
                  Spacer()
                  
                  Button(action: {
                      KeyboardShortcutHandler.shared.showSettingsPanel.toggle()
                   }) {
                       Image(systemName: "gearshape")
                           .font(.system(size: 16))
                           .foregroundColor(.white.opacity(0.6))
                   }
                   .buttonStyle(.plain)
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
        }
        .frame(width: 250) // Slightly wider for Arc feel
        .background(
            ZStack {
                Color.bgSidebar.opacity(0.6)
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                    .opacity(0.8)
            }
        )
        .dropDestination(for: Web.Tab.self) { tabs, location in
            handleTabDrop(tabs: tabs, location: location)
            return true
        } isTargeted: { isTargeted in
             withAnimation(.easeInOut(duration: 0.2)) {
                if !isTargeted {
                    dropTargetIndex = nil
                    isDragging = false
                }
            }
        }
    }
    
    // ARC STYLE NEW TAB BUTTON
    private var newTabButton: some View {
        Button(action: {
            _ = tabManager.createNewTab()
        }) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text("New Tab")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .padding(.horizontal, 16)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func handleTabDrop(tabs: [Web.Tab], location: CGPoint) {
        guard let droppedTab = tabs.first,
              let fromIndex = tabManager.tabs.firstIndex(where: { $0.id == droppedTab.id }) else { return }
        
        let tabHeight: CGFloat = 40 // Adjusted for new tab size
        let spacing: CGFloat = 2
        // Adjust offset based on new header height estimation
        let adjustedY = max(0, location.y - 120) 
        
        let tabIndex = Int(adjustedY / (tabHeight + spacing))
        let positionInTab = adjustedY.truncatingRemainder(dividingBy: tabHeight + spacing)
        
        // ... (rest of logic similar, just need to update move)
        let dropIndex = min(max(0, tabIndex), tabManager.tabs.count)
        
         let isValidDrop = dropIndex != fromIndex
         
         withAnimation(.easeInOut(duration: 0.15)) {
            dropTargetIndex = dropIndex // Simple insertion point
            isValidDropTarget = isValidDrop
         }
         
         if isValidDrop {
             _ = tabManager.moveTabSafely(fromIndex: fromIndex, toIndex: dropIndex)
         }
         
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                dropTargetIndex = nil
                isDragging = false
                draggedTab = nil
            }
         }
    }
}

struct SidebarTabItem: View {
    let tab: Web.Tab
    let isActive: Bool
    let isHovered: Bool
    let isDragging: Bool
    let tabManager: TabManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Favicon
                if tab.isLoading {
                   ProgressView()
                       .scaleEffect(0.5)
                       .frame(width: 16, height: 16)
                } else {
                   FaviconView(tab: tab, size: 16)
                       .frame(width: 16, height: 16)
                       .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                
                // Title
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                
                Spacer()
                
                // Close Button (Hover only)
                if isHovered {
                    Button(action: {
                        tabManager.closeTab(tab)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 18, height: 18)
                            .background(Color.white.opacity(0.1))
                            .mask(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Audio Indicator if playing...
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.accentBlue : (isHovered ? Color.white.opacity(0.05) : Color.clear))
            )
        }
        .buttonStyle(.plain)
    }
}

struct SidebarTabPreview: View {
    let tab: Web.Tab
    let isDragging: Bool
    
    var body: some View {
        HStack {
            FaviconView(tab: tab, size: 24)
            Text(tab.title)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
    }
}

