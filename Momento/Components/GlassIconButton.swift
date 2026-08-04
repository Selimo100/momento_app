import SwiftUI

struct GlassIconButton: View {
    let icon: String
    var size: CGFloat = 36
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .glassEffect(.regular, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
