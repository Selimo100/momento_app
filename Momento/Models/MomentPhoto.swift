import Foundation
import SwiftData

@Model
final class MomentPhoto {
    var id: UUID
    var localIdentifier: String
    var isFavorite: Bool
    var addedAt: Date

    var moment: Moment?

    init(localIdentifier: String) {
        self.id = UUID()
        self.localIdentifier = localIdentifier
        self.isFavorite = false
        self.addedAt = .now
    }
}
