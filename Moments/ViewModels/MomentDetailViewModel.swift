import SwiftUI
import SwiftData
import Photos
import PhotosUI

enum ExportScope {
    case all, favoritesOnly
}

@MainActor
@Observable
final class MomentDetailViewModel {
    var showingPhotoPicker = false
    var showingExportSheet = false
    var showingPhotoDetail = false
    var selectedPhoto: MomentPhoto?

    var isExporting = false
    var exportResultMessage: String?
    var showExportResult = false
    var exportAlbumName = ""

    var photoPickerItems: [PhotosPickerItem] = []

    func loadPickerItems(_ items: [PhotosPickerItem], into moment: Moment, context: ModelContext) async {
        for item in items {
            if let identifier = item.itemIdentifier {
                guard !moment.photos.contains(where: { $0.localIdentifier == identifier }) else { continue }
                let photo = MomentPhoto(localIdentifier: identifier)
                photo.moment = moment
                moment.photos.append(photo)
            } else {
                // Fallback: resolve identifier by fetching the asset through PHPickerResult
                if let identifier = await resolveIdentifier(from: item) {
                    guard !moment.photos.contains(where: { $0.localIdentifier == identifier }) else { continue }
                    let photo = MomentPhoto(localIdentifier: identifier)
                    photo.moment = moment
                    moment.photos.append(photo)
                }
            }
        }
        moment.updatedAt = .now
        try? context.save()
    }

    private func resolveIdentifier(from item: PhotosPickerItem) async -> String? {
        // Try to load a UIImage and find the matching asset by comparing pixel size
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return nil }
        let size = image.size
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "pixelWidth == %d AND pixelHeight == %d",
            Int(size.width), Int(size.height)
        )
        options.fetchLimit = 1
        let result = PHAsset.fetchAssets(with: .image, options: options)
        return result.firstObject?.localIdentifier
    }

    func toggleFavorite(_ photo: MomentPhoto, in moment: Moment, context: ModelContext) {
        photo.isFavorite.toggle()
        moment.updatedAt = .now
        try? context.save()
    }

    func setCover(_ photo: MomentPhoto, in moment: Moment, context: ModelContext) {
        moment.coverPhotoId = photo.id
        moment.updatedAt = .now
        try? context.save()
    }

    func removePhoto(_ photo: MomentPhoto, from moment: Moment, context: ModelContext) {
        if moment.coverPhotoId == photo.id {
            let remaining = moment.photos.filter { $0.id != photo.id }
            moment.coverPhotoId = remaining.first?.id
        }
        if moment.beforePhotoId == photo.id { moment.beforePhotoId = nil }
        if moment.afterPhotoId == photo.id { moment.afterPhotoId = nil }
        moment.photos.removeAll { $0.id == photo.id }
        context.delete(photo)
        moment.updatedAt = .now
        try? context.save()
    }

    func export(moment: Moment, scope: ExportScope, context: ModelContext) async {
        isExporting = true

        let candidates: [MomentPhoto]
        switch scope {
        case .all:
            candidates = moment.photos
        case .favoritesOnly:
            candidates = moment.photos.filter(\.isFavorite)
        }

        guard !candidates.isEmpty else {
            exportResultMessage = scope == .favoritesOnly
                ? "There are no favorite photos in this moment."
                : "This moment has no photos to export."
            showExportResult = true
            isExporting = false
            return
        }

        let identifiers = candidates.map(\.localIdentifier)
        let result = await PhotoExportService.shared.export(
            identifiers: identifiers,
            toAlbumNamed: exportAlbumName
        )

        switch result {
        case .success(let count, let album):
            exportResultMessage = "Exported \(count) \(count == 1 ? "photo" : "photos") to \"\(album)\"."
            moment.hasBeenExported = true
            moment.lastExportedAt = .now
            try? context.save()
        case .partial(let exported, let total, let album):
            exportResultMessage = "Exported \(exported) of \(total) photos to \"\(album)\". \(total - exported) could not be found."
            moment.hasBeenExported = true
            moment.lastExportedAt = .now
            try? context.save()
        case .failure(let error):
            exportResultMessage = error.errorDescription
        }

        isExporting = false
        showExportResult = true
        showingExportSheet = false
    }

    func defaultAlbumName(for moment: Moment, prefix: String) -> String {
        "\(prefix) \(moment.title)"
    }
}
