import SwiftUI

/// Shows only the best shots. All photos stay reachable through a small
/// secondary action so nothing is ever hidden for good.
struct FavoritesOnlyLayoutView: View {
    let moment: Moment
    let actions: MomentPhotoLayoutActions

    @State private var showingAllPhotos = false

    private var favorites: [MomentPhoto] { moment.favoritePhotos }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if favorites.isEmpty {
                emptyFavoritesCard
            } else {
                SectionCard(insets: 10) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(favorites) { photo in
                            PhotoThumbnailView(
                                photo: photo,
                                isCover: photo.id == moment.coverPhotoId,
                                cornerRadius: 16
                            ) {
                                actions.openPhoto(photo)
                            }
                        }
                    }
                }
            }

            if !showingAllPhotos {
                secondaryAction(
                    title: "Show all photos (\(moment.photos.count))",
                    icon: "square.grid.2x2"
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) { showingAllPhotos = true }
                }
            } else {
                SectionCard(insets: 10) {
                    PhotoGridView(
                        photos: moment.photos,
                        coverPhotoId: moment.coverPhotoId,
                        onTap: actions.openPhoto
                    )
                }

                secondaryAction(title: "Hide all photos", icon: "chevron.up") {
                    withAnimation(.easeInOut(duration: 0.25)) { showingAllPhotos = false }
                }
            }
        }
    }

    private var emptyFavoritesCard: some View {
        SectionCard {
            VStack(spacing: 10) {
                Image(systemName: "heart")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.tertiary)

                Text("No best shots yet")
                    .font(.system(size: 16, weight: .semibold))

                Text("Mark a photo as a favorite to feature it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    private func secondaryAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
