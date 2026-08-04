import SwiftUI

struct SectionCard<Content: View>: View {
    var insets: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(insets)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
