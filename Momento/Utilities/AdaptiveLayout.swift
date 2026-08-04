import SwiftUI

/// Layout helpers that keep the UI comfortable on iPad.
///
/// The app is designed around a phone-width column. On a 13" iPad every card
/// would otherwise stretch edge to edge, which looks stretched rather than
/// spacious, so content is capped at a readable width and centred instead.
enum AdaptiveLayout {
    /// Widest a content column is allowed to grow before it gets centred.
    static let contentMaxWidth: CGFloat = 700

    /// Horizontal padding around the content column per size class.
    static func horizontalPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 24 : 16
    }
}

private struct AdaptiveContentWidth: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let maxWidth: CGFloat
    let includeHorizontalPadding: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, includeHorizontalPadding
                     ? AdaptiveLayout.horizontalPadding(horizontalSizeClass)
                     : 0)
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    /// Caps the view at a readable column width, centred in the available space.
    ///
    /// - Parameters:
    ///   - maxWidth: Widest the column may become.
    ///   - includeHorizontalPadding: Adds the size-class-aware side padding.
    ///     Pass `false` when the caller already applies its own padding.
    func adaptiveContentWidth(
        maxWidth: CGFloat = AdaptiveLayout.contentMaxWidth,
        includeHorizontalPadding: Bool = true
    ) -> some View {
        modifier(AdaptiveContentWidth(
            maxWidth: maxWidth,
            includeHorizontalPadding: includeHorizontalPadding
        ))
    }
}
