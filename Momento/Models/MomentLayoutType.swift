import Foundation

/// Visual style used to present a moment's photos on the detail screen.
///
/// Persisted on `Moment` as a raw `String` so existing moments keep working:
/// anything unknown or missing falls back to ``story``.
enum MomentLayoutType: String, CaseIterable, Identifiable, Sendable {
    case story
    case timeline
    case collage
    case favoritesOnly
    case photoDump
    case beforeAfter

    var id: String { rawValue }

    static let fallback: MomentLayoutType = .story

    /// Safe conversion for values coming out of SwiftData.
    static func resolve(_ raw: String?) -> MomentLayoutType {
        guard let raw, let type = MomentLayoutType(rawValue: raw) else { return fallback }
        return type
    }

    var label: String {
        switch self {
        case .story:         return "Story"
        case .timeline:      return "Timeline"
        case .collage:       return "Collage"
        case .favoritesOnly: return "Favorites Only"
        case .photoDump:     return "Photo Dump"
        case .beforeAfter:   return "Before / After"
        }
    }

    var icon: String {
        switch self {
        case .story:         return "book.pages"
        case .timeline:      return "list.bullet.rectangle"
        case .collage:       return "square.grid.2x2"
        case .favoritesOnly: return "heart"
        case .photoDump:     return "square.grid.3x3"
        case .beforeAfter:   return "rectangle.split.2x1"
        }
    }

    var summary: String {
        switch self {
        case .story:         return "Hero image with your story and a clean grid."
        case .timeline:      return "Photos in order, along a vertical timeline."
        case .collage:       return "Editorial mix of large and small photos."
        case .favoritesOnly: return "Only your best shots take the stage."
        case .photoDump:     return "A dense, casual grid of everything."
        case .beforeAfter:   return "Two photos side by side to show the change."
        }
    }
}
