import SwiftUI

struct MoodChipView: View {
    let mood: String

    var body: some View {
        Text(mood)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
    }
}
