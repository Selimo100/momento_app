import SwiftUI

/// Photos in chronological order along a subtle vertical rail.
/// Good for trips and events where the order tells the story.
struct TimelinePhotoLayoutView: View {
    let moment: Moment
    let actions: MomentPhotoLayoutActions

    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    private var photos: [MomentPhoto] { moment.sortedPhotos }

    var body: some View {
        SectionCard(insets: 14) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    row(for: photo, isLast: index == photos.count - 1)
                }
            }
        }
    }

    private func row(for photo: MomentPhoto, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            rail(isLast: isLast)

            VStack(alignment: .leading, spacing: 8) {
                Text(DateFormatter.momentDate.string(from: photo.addedAt))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Color.clear
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .overlay {
                        AssetThumbnailView(
                            localIdentifier: photo.localIdentifier,
                            targetSize: CGSize(width: 800, height: 600)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .overlay(alignment: .topTrailing) { badges(for: photo) }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture { actions.openPhoto(photo) }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Photo from \(DateFormatter.momentDate.string(from: photo.addedAt))")
            }
            .padding(.bottom, isLast ? 0 : 18)
        }
    }

    private func rail(isLast: Bool) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color(hex: accentColorHex))
                .frame(width: 9, height: 9)
                .padding(.top, 5)

            if !isLast {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 9)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func badges(for photo: MomentPhoto) -> some View {
        HStack(spacing: 5) {
            if photo.id == moment.coverPhotoId {
                badge(icon: "star.fill", tint: .yellow)
            }
            if photo.isFavorite {
                badge(icon: "heart.fill", tint: .pink)
            }
        }
        .padding(8)
    }

    private func badge(icon: String, tint: Color) -> some View {
        Image(systemName: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(5)
            .background(.ultraThinMaterial, in: Circle())
    }
}
