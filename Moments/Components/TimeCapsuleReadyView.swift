import SwiftUI

struct TimeCapsuleReadyView: View {
    let moment: Moment
    let onReopen: () -> Void

    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 40)

            giftIcon
            messageSection
            reopenButton

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, minHeight: 380)
    }

    // MARK: Gift icon with glowing ring

    private var giftIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: accentColorHex).opacity(0.12))
                .frame(width: 116, height: 116)
            Circle()
                .stroke(Color(hex: accentColorHex).opacity(0.3), lineWidth: 1.5)
                .frame(width: 116, height: 116)
            Circle()
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(width: 88, height: 88)
            Image(systemName: "gift.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Color(hex: accentColorHex))
        }
    }

    // MARK: Message

    private var messageSection: some View {
        VStack(spacing: 10) {
            Text("A memory is ready to reopen")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let unlockDate = moment.unlockDate {
                Text("This moment was sealed until \(DateFormatter.momentDate.string(from: unlockDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let lockedAt = moment.lockedAt {
                Text("Sealed on \(DateFormatter.momentShort.string(from: lockedAt))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: Reopen Button

    private var reopenButton: some View {
        Button(action: onReopen) {
            Label("Reopen this Memory", systemImage: "lock.open.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: accentColorHex))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
