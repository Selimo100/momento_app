import SwiftUI

struct PhotoThumbnailView: View {
    let photo: MomentPhoto
    let isCover: Bool
    let cornerRadius: CGFloat
    let onTap: () -> Void

    init(
        photo: MomentPhoto,
        isCover: Bool,
        cornerRadius: CGFloat = 18,
        onTap: @escaping () -> Void
    ) {
        self.photo = photo
        self.isCover = isCover
        self.cornerRadius = cornerRadius
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    AssetThumbnailView(
                        localIdentifier: photo.localIdentifier,
                        targetSize: CGSize(width: 300, height: 300)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .overlay(alignment: .topTrailing) {
                    badgesView
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var badgesView: some View {
        if isCover || photo.isFavorite {
            VStack(alignment: .trailing, spacing: 3) {
                if isCover {
                    Image(systemName: "star.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.yellow)
                        .padding(5)
                        .glassEffect(.regular, in: Circle())
                }
                if photo.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.pink)
                        .padding(5)
                        .glassEffect(.regular, in: Circle())
                }
            }
            .padding(5)
        }
    }
}
