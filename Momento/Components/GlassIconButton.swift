import SwiftUI

/// The circular glass chrome used for buttons that float over artwork.
///
/// Split out from `GlassIconButton` so toolbar code can wrap it in its own
/// `Button` — iPhone Duo needs the button itself to be a plain toolbar item.
struct GlassIconLabel: View {
    let icon: String
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .glassEffect(.regular, in: Circle())
    }
}

struct GlassIconButton: View {
    let icon: String
    var size: CGFloat = 36
    /// Spoken description, since the glyph alone carries the meaning.
    var accessibilityTitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassIconLabel(icon: icon, size: size)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle ?? "")
    }
}
