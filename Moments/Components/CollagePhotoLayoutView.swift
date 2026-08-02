import SwiftUI

/// Editorial collage: one large lead photo, a pair beneath it, then an even
/// grid for the rest. Degrades gracefully for moments with only one or two photos.
struct CollagePhotoLayoutView: View {
    let moment: Moment
    let actions: MomentPhotoLayoutActions

    private let spacing: CGFloat = 10

    private var photos: [MomentPhoto] { moment.sortedPhotos }
    private var lead: MomentPhoto? { photos.first }
    private var pair: [MomentPhoto] { Array(photos.dropFirst().prefix(2)) }
    private var rest: [MomentPhoto] { Array(photos.dropFirst(3)) }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        SectionCard(insets: 10) {
            VStack(spacing: spacing) {
                if let lead {
                    tile(for: lead, aspectRatio: 4 / 3, cornerRadius: 18)
                }

                if !pair.isEmpty {
                    HStack(spacing: spacing) {
                        ForEach(pair) { photo in
                            tile(for: photo, aspectRatio: 1, cornerRadius: 16)
                        }
                        // Keep a single second photo at half width instead of
                        // stretching it across the row.
                        if pair.count == 1 {
                            Color.clear.aspectRatio(1, contentMode: .fit)
                        }
                    }
                }

                if !rest.isEmpty {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(rest) { photo in
                            PhotoThumbnailView(
                                photo: photo,
                                isCover: photo.id == moment.coverPhotoId,
                                cornerRadius: 14
                            ) {
                                actions.openPhoto(photo)
                            }
                        }
                    }
                }
            }
        }
    }

    private func tile(for photo: MomentPhoto, aspectRatio: CGFloat, cornerRadius: CGFloat) -> some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                AssetThumbnailView(
                    localIdentifier: photo.localIdentifier,
                    targetSize: CGSize(width: 900, height: 900)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 5) {
                    if photo.id == moment.coverPhotoId {
                        collageBadge(icon: "star.fill", tint: .yellow)
                    }
                    if photo.isFavorite {
                        collageBadge(icon: "heart.fill", tint: .pink)
                    }
                }
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onTapGesture { actions.openPhoto(photo) }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Photo")
    }

    private func collageBadge(icon: String, tint: Color) -> some View {
        Image(systemName: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(5)
            .background(.ultraThinMaterial, in: Circle())
    }
}
