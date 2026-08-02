import SwiftUI

struct RootView: View {
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    @Environment(\.scenePhase) private var scenePhase
    @State private var lock = PrivacyLockService.shared
    /// Covers the UI while the app is not active, but only when private
    /// content could be on screen — normal browsing is never interrupted.
    @State private var showShield = false

    var body: some View {
        TabView {
            Tab("Momento", systemImage: "photo.on.rectangle.angled") {
                MomentListView()
            }
            Tab("Time Capsule", systemImage: "hourglass") {
                TimeCapsuleListView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tint(Color(hex: accentColorHex))
        .overlay {
            if showShield {
                PrivacyShieldView()
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showShield)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                showShield = false
            default:
                // Leaving the foreground always ends the private session, so
                // returning to the app requires authenticating again.
                showShield = lock.isUnlocked
                lock.lock()
            }
        }
    }
}
