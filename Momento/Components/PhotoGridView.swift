import SwiftUI

struct PhotoGridView: View {
    let photos: [MomentPhoto]
    let coverPhotoId: UUID?
    let onTap: (MomentPhoto) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(photos.sorted { $0.addedAt < $1.addedAt }) { photo in
                PhotoThumbnailView(
                    photo: photo,
                    isCover: photo.id == coverPhotoId
                ) {
                    onTap(photo)
                }
            }
        }
    }
}
