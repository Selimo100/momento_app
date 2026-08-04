import Photos
import UIKit

enum PhotoAuthorizationStatus {
    case notDetermined, authorized, limited, denied, restricted
}

final class PhotoLibraryService: Sendable {
    static let shared = PhotoLibraryService()
    private init() {}

    var authorizationStatus: PhotoAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    func requestAuthorization() async -> PhotoAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    func assetExists(localIdentifier: String) -> Bool {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return result.count > 0
    }
}
