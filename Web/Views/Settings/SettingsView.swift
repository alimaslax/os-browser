import SwiftUI
import WebKit

/// Main settings view with comprehensive browser configuration options
/// Follows next-gen glass morphism design with category tabs
struct SettingsView: View {
    @State private var selectedCategory: SettingsCategory = .general
    @State private var contentOpacity = 0.0
    @State private var hoveredCategory: SettingsCategory?

    enum SettingsCategory: String, CaseIterable {
        case general = "General"
        case aiProvider = "AI Provider"
        case privacy = "Privacy"
        case usageBilling = "Usage & Billing"
        case security = "Security"
        case appearance = "Appearance"
        case advanced = "Advanced"

        var icon: String {
            switch self {
            case .general: return "gear"
            case .aiProvider: return "brain.head.profile"
            case .privacy: return "hand.raised"
            case .security: return "lock.shield"
            case .appearance: return "paintbrush"
            case .advanced: return "terminal"
            case .usageBilling: return "chart.bar"
            }
        }
    }

    var body: some View {
        ZStack {
            // Glass background with enhanced visual effect
            Color.bgBase
                .edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 0) {
                // Category sidebar
                categorysidebar
                    .background(Color.bgSidebar)

                // Main content area
                VStack(spacing: 0) {
                    // Header with close button
                    settingsHeader

                    Divider()
                        .opacity(0.1)
                        .padding(.horizontal, 24)

                    // Settings content area
                    settingsContent
                }
            }
            .opacity(contentOpacity)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .frame(
            minWidth: 600, idealWidth: 800, maxWidth: 1200, minHeight: 500, idealHeight: 600,
            maxHeight: 900
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                contentOpacity = 1.0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openUsageBilling)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedCategory = .usageBilling
            }
        }
    }

    private var settingsHeader: some View {
        HStack {
            Spacer()

            Button(action: {
                KeyboardShortcutHandler.shared.showSettingsPanel = false
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var categorysidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            ForEach(SettingsCategory.allCases, id: \.self) { category in
                categoryButton(category)
            }

            Spacer()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 8)
        .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)
    }

    private func categoryButton(_ category: SettingsCategory) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.6))
                    .frame(width: 16)

                Text(category.rawValue)
                    .font(
                        .system(
                            size: 14, weight: selectedCategory == category ? .semibold : .medium)
                    )
                    .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.6))

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColorForCategory(category))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredCategory = hovering ? category : nil
            }
        }
    }

    private func backgroundColorForCategory(_ category: SettingsCategory) -> Color {
        if selectedCategory == category {
            return Color.accentBlue
        } else if hoveredCategory == category {
            return .white.opacity(0.05)
        } else {
            return .clear
        }
    }

    private var settingsContent: some View {
        ScrollView {
            Group {
                switch selectedCategory {
                case .general:
                    GeneralSettingsView()
                case .aiProvider:
                    AIProviderSettingsView()
                case .privacy:
                    PrivacySettingsView()
                case .security:
                    BasicSecuritySettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .advanced:
                    AdvancedSettingsView()
                case .usageBilling:
                    UsageBillingView()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
    }
}

// MARK: - Settings Category Views

struct GeneralSettingsView: View {
    @AppStorage("defaultSearchEngine") private var defaultSearchEngine = "Google"
    @AppStorage("startupBehavior") private var startupBehavior = "new_tab"
    @AppStorage("enableDownloadNotifications") private var enableDownloadNotifications = true
    @AppStorage("autoCheckForUpdates") private var autoCheckForUpdates = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("General")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                // Search Engine
                settingsGroup("Search Engine") {
                    Picker("Default Search Engine", selection: $defaultSearchEngine) {
                        Text("Google").tag("Google")
                        Text("DuckDuckGo").tag("DuckDuckGo")
                        Text("Bing").tag("Bing")
                        Text("Yahoo").tag("Yahoo")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 200)
                }

                // Startup Behavior
                settingsGroup("Startup") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                        
                        Picker("When Web starts", selection: $startupBehavior) {
                            Text("Open a new tab").tag("new_tab")
                            Text("Restore previous session").tag("restore_session")
                            Text("Open homepage").tag("homepage")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 250)
                    }
                }

                // Notifications
                settingsGroup("Notifications") {
                    Toggle("Show download notifications", isOn: $enableDownloadNotifications)
                }

                // Updates
                settingsGroup("Updates") {
                    Toggle("Automatically check for updates", isOn: $autoCheckForUpdates)
                }
            }

            Spacer()
        }
    }
}

struct BasicSecuritySettingsView: View {
    @AppStorage("enablePasswordManager") private var enablePasswordManager = true
    @AppStorage("enableAdBlocker") private var enableAdBlocker = true
    @AppStorage("enableDNSOverHTTPS") private var enableDNSOverHTTPS = true
    @AppStorage("dnsProvider") private var dnsProvider = "Cloudflare"
    @StateObject private var safeBrowsingManager = SafeBrowsingManager.shared
    @State private var showSafeBrowsingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Security")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                // Safe Browsing (new section at top)
                settingsGroup("Safe Browsing") {
                    HStack {
                        Toggle(
                            "Protect against malware and phishing",
                            isOn: $safeBrowsingManager.isEnabled)

                        Spacer()

                        Button("Configure...") {
                            showSafeBrowsingSettings = true
                        }
                        .font(.callout)
                    }

                    HStack {
                        Image(
                            systemName: safeBrowsingManager.isEnabled
                                ? "shield.checkered" : "shield.slash"
                        )
                        .foregroundColor(safeBrowsingManager.isEnabled ? .green : .red)

                        Text(
                            safeBrowsingManager.isEnabled
                                ? "\(safeBrowsingManager.totalThreatsBlocked) threats blocked"
                                : "Malware protection disabled"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .sheet(isPresented: $showSafeBrowsingSettings) {
                    SafeBrowsingSettingsView()
                }

                // Password Manager
                settingsGroup("Password Manager") {
                    Toggle("Enable built-in password manager", isOn: $enablePasswordManager)

                    if enablePasswordManager {
                        Text(
                            "Passwords are securely stored in your Keychain with biometric authentication."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                    }
                }

                // Ad Blocker
                settingsGroup("Content Blocking") {
                    Toggle("Enable ad blocker", isOn: $enableAdBlocker)

                    if enableAdBlocker {
                        Text(
                            "Blocks ads and trackers using optimized filter lists for better performance."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                    }
                }

                // DNS over HTTPS
                settingsGroup("DNS Security") {
                    Toggle("Enable DNS over HTTPS", isOn: $enableDNSOverHTTPS)

                    if enableDNSOverHTTPS {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("DNS Provider:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Picker("DNS Provider", selection: $dnsProvider) {
                                    Text("Cloudflare").tag("Cloudflare")
                                    Text("Quad9").tag("Quad9")
                                    Text("Google").tag("Google")
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: 120)
                            }
                            .padding(.leading, 16)

                            Text(
                                "Encrypts DNS queries to protect your browsing from eavesdropping."
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                        }
                    }
                }
            }

            Spacer()
        }
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("enableGlassEffects") private var enableGlassEffects = true
    @AppStorage("enableSmoothAnimations") private var enableSmoothAnimations = true
    @AppStorage("enableFaviconColors") private var enableFaviconColors = true
    @AppStorage("windowTransparency") private var windowTransparency = "Partial"
    @AppStorage("sidebarWidth") private var sidebarWidth = 60.0

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Appearance")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                // Visual Effects
                settingsGroup("Visual Effects") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable glass morphism effects", isOn: $enableGlassEffects)
                        Toggle("Enable smooth 120fps animations", isOn: $enableSmoothAnimations)
                        Toggle("Extract colors from favicons", isOn: $enableFaviconColors)
                    }
                }

                // Window Transparency (Matched to reference image)
                settingsGroup("Window Transparency") {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Window Transparency", selection: $windowTransparency) {
                            Text("Transparent").tag("Transparent")
                            Text("Partial").tag("Partial")
                            Text("Opaque").tag("Opaque")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 300)
                        
                        Text("Semi-transparent with blur.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                // Sidebar
                settingsGroup("Sidebar") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sidebar width: \(Int(sidebarWidth)) pt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Slider(value: $sidebarWidth, in: 50...120, step: 10)
                            .frame(maxWidth: 200)
                    }
                }
            }

            Spacer()
        }
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("enableTabHibernation") private var enableTabHibernation = true
    @AppStorage("hibernationTimeout") private var hibernationTimeout = 300.0
    @AppStorage("enableDeveloperTools") private var enableDeveloperTools = true
    @AppStorage("enableExperimentalFeatures") private var enableExperimentalFeatures = false

    @State private var showingResetSettingsAlert = false
    @State private var showingClearAllDataAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Advanced")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                // Performance
                settingsGroup("Performance") {
                    Toggle("Enable tab hibernation", isOn: $enableTabHibernation)

                    if enableTabHibernation {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hibernation timeout: \(Int(hibernationTimeout / 60)) minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)

                            Slider(value: $hibernationTimeout, in: 60...1800, step: 60)
                                .frame(maxWidth: 200)
                                .padding(.leading, 16)
                        }
                    }
                }

                // Developer Features
                settingsGroup("Developer") {
                    Toggle("Enable developer tools", isOn: $enableDeveloperTools)
                    Toggle("Enable experimental features", isOn: $enableExperimentalFeatures)

                    if enableExperimentalFeatures {
                        Text("⚠️ Experimental features may be unstable and could cause crashes.")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.leading, 16)
                    }
                }

                // Reset Options
                settingsGroup("Reset") {
                    Button("Reset All Settings") {
                        showingResetSettingsAlert = true
                    }
                    .foregroundColor(.red)

                    Button("Clear All Data") {
                        showingClearAllDataAlert = true
                    }
                    .foregroundColor(.red)
                }
            }

            Spacer()
        }
        .alert("Reset All Settings", isPresented: $showingResetSettingsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text(
                "This will reset all browser settings to their default values. Your browsing history and saved data will not be affected."
            )
        }
        .alert("Clear All Data", isPresented: $showingClearAllDataAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All Data", role: .destructive) {
                clearAllBrowserData()
            }
        } message: {
            Text(
                "This will permanently delete all browsing history, cookies, cached files, saved passwords, and website data. This action cannot be undone."
            )
        }
    }

    private func resetAllSettings() {
        // Get all UserDefaults keys that are browser settings
        let settingsKeys = [
            // General settings
            "defaultSearchEngine", "startupBehavior", "enableDownloadNotifications",
            "autoCheckForUpdates",

            // Privacy settings
            "trackingProtectionEnabled", "blockThirdPartyCookies", "blockAllCookies",
            "httpsOnlyMode",
            "preventFingerprinting", "blockCrossSiteTracking", "hideMacAddress",
            "enableDNSOverHTTPS",
            "clearDataOnExit", "enableFraudProtection", "showPrivacyReport", "blockPopups",
            "enableSmartTrackingPrevention", "blockAutoplay", "enableWebsiteIsolation",

            // Security settings
            "enablePasswordManager", "enableAdBlocker", "enableDNSOverHTTPS", "dnsProvider",

            // Appearance settings
            "enableGlassEffects", "enableSmoothAnimations", "enableFaviconColors", "sidebarWidth",

            // Advanced settings
            "enableTabHibernation", "hibernationTimeout", "enableDeveloperTools",
            "enableExperimentalFeatures",
        ]

        // Remove all settings keys to restore defaults
        for key in settingsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        if AppLog.isVerboseEnabled { print("All browser settings have been reset to defaults") }

        // Post notification to update UI
        NotificationCenter.default.post(name: NSNotification.Name("SettingsReset"), object: nil)
    }

    private func clearAllBrowserData() {
        // Clear WebKit website data
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        dataStore.removeData(ofTypes: dataTypes, modifiedSince: .distantPast) {
            if AppLog.isVerboseEnabled { print("All website data cleared successfully") }
        }

        // Clear additional browser data from UserDefaults
        let dataKeys = [
            "browsingHistory", "savedPasswords", "downloadHistory",
            "bookmarks", "searchHistory", "formData", "blockedRequestsCount",
            "passwordMetadata", "adBlockSettings",
        ]

        for key in dataKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        if AppLog.isVerboseEnabled { print("All browser data has been cleared") }

        // Post notification to update UI and other components
        NotificationCenter.default.post(name: NSNotification.Name("AllDataCleared"), object: nil)
    }
}

// MARK: - Helper Views

extension View {
    func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            content()
                .padding(.leading, 12)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .frame(width: 800, height: 600)
        .background(.black.opacity(0.3))
}
