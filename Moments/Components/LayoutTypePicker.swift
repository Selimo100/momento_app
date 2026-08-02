import SwiftUI

/// Horizontal card selector for a moment's visual layout.
/// Visual enough to preview the idea, compact enough to sit inside a Form.
struct LayoutTypePicker: View {
    @Binding var selection: MomentLayoutType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(MomentLayoutType.allCases) { type in
                        card(for: type)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            Text(selection.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut(duration: 0.2), value: selection)
        }
    }

    private func card(for type: MomentLayoutType) -> some View {
        let isSelected = type == selection
        return Button {
            withAnimation(.snappy(duration: 0.2)) { selection = type }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                Text(type.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(width: 96, height: 82)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected
                          ? Color.accentColor.opacity(0.12)
                          : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.label)
        .accessibilityHint(type.summary)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
