import SwiftUI

/// Calm, premium locked panel used by the private area and by private moments
/// that are opened while the session is locked.
struct PrivacyLockedStateView: View {
    var title: String
    var message: String
    var actionTitle: String
    var isAuthenticating: Bool = false
    var errorMessage: String?
    let action: () -> Void

    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    private var lock: PrivacyLockService { .shared }

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(Color(hex: accentColorHex).opacity(0.12))
                    .frame(width: 92, height: 92)

                Image(systemName: lock.biometryIcon)
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(Color(hex: accentColorHex))
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isAuthenticating {
                ProgressView()
                    .padding(.vertical, 6)
            } else {
                PrimaryButton(actionTitle, icon: lock.biometryIcon, action: action)
                    .disabled(!lock.canAuthenticate)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// Full-screen cover shown while the app is not active, so private content is
/// never captured in the app switcher snapshot.
struct PrivacyShieldView: View {
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Color(hex: accentColorHex))

                Text("Private moments are hidden")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .transition(.opacity)
    }
}
