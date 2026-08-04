import UIKit
import Photos

enum PermissionHelpers {
    @MainActor
    static func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    static var photoLibraryAccessDescription: String {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .limited:
            return "You have granted limited photo access. You can only add photos from your selected library."
        case .denied, .restricted:
            return "Photo access is required to add and export photos. Please enable it in Settings."
        default:
            return "Photo access lets you add photos to moments and export them to albums."
        }
    }
}
