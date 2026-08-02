import SwiftUI

/// The classic Momento look: an even, generous three-column grid.
/// The hero image and story card above it are provided by the detail screen.
struct StoryPhotoLayoutView: View {
    let moment: Moment
    let actions: MomentPhotoLayoutActions

    var body: some View {
        SectionCard(insets: 10) {
            PhotoGridView(
                photos: moment.photos,
                coverPhotoId: moment.coverPhotoId,
                onTap: actions.openPhoto
            )
        }
    }
}
