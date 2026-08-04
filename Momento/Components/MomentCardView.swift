import SwiftUI

struct MomentCardView: View {
    let moment: Moment
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImageArea
            infoArea
            completionStrip
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.25 : 0.09),
            radius: 14,
            x: 0,
            y: 5
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    moment.isReadyToReopen
                        ? Color(hex: accentColorHex).opacity(0.45)
                        : Color.clear,
                    lineWidth: 1.5
                )
        )
    }

    // MARK: Cover

    @ViewBuilder
    private var coverImageArea: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image or placeholder
            if let cover = moment.coverPhoto {
                AssetThumbnailView(
                    localIdentifier: cover.localIdentifier,
                    targetSize: CGSize(width: 800, height: 500)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .blur(radius: moment.isLocked ? 14 : 0)
                .animation(.easeInOut(duration: 0.3), value: moment.isLocked)
            } else {
                LinearGradient(
                    colors: [Color(.systemGray5), Color(.systemGray4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 220)
                .overlay {
                    if !moment.isTimeCapsule {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // Tint overlay when locked
            if moment.isLocked {
                Color.black.opacity(0.3).frame(height: 220)
            }

            // Bottom gradient scrim
            LinearGradient(
                colors: [.clear, .black.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 220)

            // Centre icon for capsule states
            if moment.isTimeCapsule {
                capsuleCenterIcon
                    .frame(maxWidth: .infinity, maxHeight: 220)
            }

            // Bottom-left badge
            capsuleBadge
                .padding(12)
        }
    }

    @ViewBuilder
    private var capsuleCenterIcon: some View {
        VStack {
            Spacer()
            Image(systemName: moment.isLocked ? "lock.fill" : "gift.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            Spacer()
        }
    }

    @ViewBuilder
    private var capsuleBadge: some View {
        if moment.isTimeCapsule {
            HStack(spacing: 4) {
                Image(systemName: moment.isLocked ? "lock.fill" : "gift.fill")
                    .font(.caption2.weight(.semibold))
                Text(moment.isLocked ? "Sealed" : "Ready to Reopen")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .glassEffect(.regular, in: Capsule())
        } else if moment.photos.count > 0 {
            HStack(spacing: 4) {
                Image(systemName: "photo.stack")
                    .font(.caption2.weight(.semibold))
                Text("\(moment.photos.count)")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .glassEffect(.regular, in: Capsule())
        }
    }

    // MARK: Completion strip

    private var completionStrip: some View {
        Group {
            if moment.isLocked {
                Color(.systemGray5).frame(height: 3)
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                        Rectangle()
                            .fill(Color(hex: accentColorHex).opacity(0.75))
                            .frame(width: geo.size.width * CGFloat(moment.completionPercentage) / 100)
                    }
                }
                .frame(height: 3)
            }
        }
    }

    // MARK: Info area

    private var infoArea: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(moment.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if moment.isLocked, let unlockDate = moment.unlockDate {
                    Label(
                        "Opens \(DateFormatter.momentShort.string(from: unlockDate))",
                        systemImage: "clock"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                } else if moment.isReadyToReopen {
                    Label("Ready to reopen", systemImage: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: accentColorHex))
                        .lineLimit(1)
                } else {
                    if let dateText = moment.shortDateDisplay {
                        Text(dateText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let mood = moment.mood {
                        MoodChipView(mood: mood)
                    }
                }
            }

            Spacer()

            if !moment.isTimeCapsule, moment.favoriteCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.pink)
                    Text("\(moment.favoriteCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
