import Photos
import UIKit

enum ExportResult {
    case success(exported: Int, albumName: String)
    case partial(exported: Int, total: Int, albumName: String)
    case failure(ExportError)
}

enum ExportError: LocalizedError {
    case noPhotos
    case noFavorites
    case permissionDenied
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noPhotos:
            return "This moment has no photos to export."
        case .noFavorites:
            return "There are no favorite photos in this moment."
        case .permissionDenied:
            return "Photo access is required to export photos. Please enable it in Settings."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

final class PhotoExportService: Sendable {
    static let shared = PhotoExportService()
    private init() {}

    func export(
        identifiers: [String],
        toAlbumNamed albumName: String
    ) async -> ExportResult {
        guard !identifiers.isEmpty else {
            return .failure(.noPhotos)
        }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            return .failure(.permissionDenied)
        }

        let targetAlbumName = uniqueAlbumName(preferred: albumName)
        var exportedCount = 0
        var failedCount = 0

        do {
            let collection = try await createOrFetchAlbum(named: targetAlbumName)
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

            try await PHPhotoLibrary.shared().performChanges {
                guard let request = PHAssetCollectionChangeRequest(for: collection) else { return }
                var assetsToAdd: [PHAsset] = []
                assets.enumerateObjects { asset, _, _ in
                    assetsToAdd.append(asset)
                }
                request.addAssets(assetsToAdd as NSFastEnumeration)
            }

            exportedCount = assets.count
            failedCount = identifiers.count - assets.count

            if failedCount > 0 {
                return .partial(exported: exportedCount, total: identifiers.count, albumName: targetAlbumName)
            }
            return .success(exported: exportedCount, albumName: targetAlbumName)
        } catch {
            return .failure(.unknown(error))
        }
    }

    private func createOrFetchAlbum(named name: String) async throws -> PHAssetCollection {
        if let existing = fetchAlbum(named: name) {
            return existing
        }

        var collectionPlaceholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            collectionPlaceholder = request.placeholderForCreatedAssetCollection
        }

        guard let identifier = collectionPlaceholder?.localIdentifier,
              let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil).firstObject
        else {
            throw NSError(domain: "PhotoExportService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create album."])
        }
        return collection
    }

    private func fetchAlbum(named name: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", name)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
        return collections.firstObject
    }

    private func uniqueAlbumName(preferred name: String) -> String {
        guard fetchAlbum(named: name) != nil else { return name }
        var suffix = 2
        while true {
            let candidate = "\(name) (\(suffix))"
            if fetchAlbum(named: candidate) == nil {
                return candidate
            }
            suffix += 1
        }
    }
}
