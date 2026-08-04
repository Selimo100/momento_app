import SwiftUI

struct TimeCapsuleLockedView: View {
    let moment: Moment
    let onUnlockEarly: () -> Void

    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 40)

            lockIcon
            messageSection
            unlockEarlyButton

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, minHeight: 380)
    }

    // MARK: Lock icon with glowing ring

    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: accentColorHex).opacity(0.08))
                .frame(width: 116, height: 116)
            Circle()
                .stroke(Color(hex: accentColorHex).opacity(0.18), lineWidth: 1.5)
                .frame(width: 116, height: 116)
            Circle()
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(width: 88, height: 88)
            Image(systemName: "lock.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Color(hex: accentColorHex))
        }
    }

    // MARK: Message

    private var messageSection: some View {
        VStack(spacing: 10) {
            Text("This memory is sealed")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let unlockDate = moment.unlockDate {
                Text("It will reopen on \(DateFormatter.momentDate.string(from: unlockDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let lockedAt = moment.lockedAt {
                Text("Sealed \(DateFormatter.momentShort.string(from: lockedAt))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: Unlock Early

    private var unlockEarlyButton: some View {
        Button(action: onUnlockEarly) {
            Label("Unlock Early", systemImage: "lock.open")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
