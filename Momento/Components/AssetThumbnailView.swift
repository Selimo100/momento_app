import SwiftUI
import Photos

struct AssetThumbnailView: View {
    let localIdentifier: String
    let targetSize: CGSize

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .task(id: localIdentifier) {
            image = await ImageLoadingService.shared.thumbnail(for: localIdentifier, targetSize: targetSize)
        }
    }
}
