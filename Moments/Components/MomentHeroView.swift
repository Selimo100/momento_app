import SwiftUI

struct MomentHeroView: View {
    let moment: Moment
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    @ScaledMetric(relativeTo: .largeTitle) private var heroHeight: CGFloat = 380

    var body: some View {
        ZStack(alignment: .bottom) {
            // Centre lock icon when sealed
            if moment.isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white.opacity(0.6))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    .frame(maxHeight: .infinity)
                    .accessibilityHidden(true)
            }

            // Info overlay
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if moment.isLocked {
                        heroBadge(icon: "lock.fill", text: "Sealed")
                    } else if moment.isReadyToReopen {
                        heroBadge(icon: "gift.fill", text: "Ready to Reopen",
                                  tint: Color(hex: accentColorHex))
                    } else {
                        if moment.photos.count > 0 {
                            heroBadge(
                                icon: "photo.stack",
                                text: "\(moment.photos.count) \(moment.photos.count == 1 ? "photo" : "photos")"
                            )
                        }
                        if moment.favoriteCount > 0 {
                            heroBadge(icon: "heart.fill", text: "\(moment.favoriteCount)", tint: .pink)
                        }
                    }
                }

                Text(moment.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                if moment.isLocked, let unlockDate = moment.unlockDate {
                    Text("Opens \(DateFormatter.momentDate.string(from: unlockDate))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                } else if let dateText = moment.dateDisplay {
                    Text(dateText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        // The cover lives in a background layer so its aspect-fill overflow
        // never grows the hero's own layout size in either direction.
        .frame(maxWidth: .infinity, alignment: .bottom)
        .frame(height: heroHeight, alignment: .bottom)
        .background {
            ZStack {
                coverBackground
                scrim
            }
        }
        .clipped()
        .accessibilityElement(children: .combine)
    }

    private var scrim: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: 0.35),
                .init(color: .black.opacity(0.25), location: 0.6),
                .init(color: .black.opacity(0.65), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    @ViewBuilder
    private var coverBackground: some View {
        if let cover = moment.coverPhoto {
            AssetThumbnailView(
                localIdentifier: cover.localIdentifier,
                targetSize: CGSize(width: 800, height: 760)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .blur(radius: moment.isLocked ? 16 : 0)
            .overlay {
                if moment.isLocked {
                    Color.black.opacity(0.25)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: moment.isLocked)
        } else {
            LinearGradient(
                colors: [Color(.systemGray4), Color(.systemGray5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if !moment.isTimeCapsule {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(.tertiary)
                        Text("No cover photo")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func heroBadge(icon: String, text: String, tint: Color = .white) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .glassEffect(.regular, in: Capsule())
    }
}
