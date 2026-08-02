import SwiftUI

/// Dense, casual four-column grid — everything visible at once, tight spacing,
/// still rounded and clean.
struct PhotoDumpLayoutView: View {
    let moment: Moment
    let actions: MomentPhotoLayoutActions

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 4),
        count: 4
    )

    var body: some View {
        SectionCard(insets: 8) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(moment.sortedPhotos) { photo in
                    PhotoThumbnailView(
                        photo: photo,
                        isCover: photo.id == moment.coverPhotoId,
                        cornerRadius: 8
                    ) {
                        actions.openPhoto(photo)
                    }
                }
            }
        }
    }
}
