import UIKit
import Photos

actor ImageLoadingService {
    static let shared = ImageLoadingService()
    private let imageManager = PHCachingImageManager()
    private var cache: [String: UIImage] = [:]

    private init() {}

    func thumbnail(for identifier: String, targetSize: CGSize = CGSize(width: 300, height: 300)) async -> UIImage? {
        let cacheKey = "\(identifier)-\(Int(targetSize.width))"
        if let cached = cache[cacheKey] {
            return cached
        }
        let result = await fetchImage(identifier: identifier, targetSize: targetSize, contentMode: .aspectFill)
        if let result {
            cache[cacheKey] = result
        }
        return result
    }

    func fullResolution(for identifier: String) async -> UIImage? {
        await fetchImage(identifier: identifier, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit)
    }

    private func fetchImage(identifier: String, targetSize: CGSize, contentMode: PHImageContentMode) async -> UIImage? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = assets.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            // Always use highQualityFormat so the callback fires exactly once.
            // opportunistic fires twice (degraded + final) which would crash withCheckedContinuation.
            options.deliveryMode = .highQualityFormat
            options.resizeMode = targetSize == PHImageManagerMaximumSize ? .none : .fast
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    func clearCache() {
        cache.removeAll()
    }
}
