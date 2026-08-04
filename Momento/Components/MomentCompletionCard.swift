import SwiftUI

struct MomentCompletionCard: View {
    let moment: Moment
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    private var percentage: Int { moment.completionPercentage }
    private var criteria: [CompletionCriterion] { moment.completionCriteria }
    private var accentColor: Color { Color(hex: accentColorHex) }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                header
                progressBar
                hintText
                checklist
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Moment Completion")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            Spacer()

            Text("\(percentage)%")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(percentage == 100 ? accentColor : .primary)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: percentage)
        }
    }

    // MARK: Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(barColor)
                    .frame(width: max(0, geo.size.width * CGFloat(percentage) / 100))
                    .animation(.spring(duration: 0.5), value: percentage)
            }
        }
        .frame(height: 6)
    }

    // MARK: Hint

    private var hintText: some View {
        Text(moment.completionHint)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Checklist

    private var checklist: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(criteria, id: \.label) { criterion in
                CriterionRow(criterion: criterion, accentColor: accentColor)
            }
        }
    }

    // MARK: Helpers

    private var barColor: Color {
        switch percentage {
        case 100:   return accentColor
        case 60...: return .green.opacity(0.8)
        case 30...: return .orange.opacity(0.8)
        default:    return .red.opacity(0.6)
        }
    }
}

// MARK: - Criterion Row

private struct CriterionRow: View {
    let criterion: CompletionCriterion
    let accentColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: criterion.isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(criterion.isComplete ? accentColor : Color(.systemGray3))
                .animation(.spring(duration: 0.3), value: criterion.isComplete)

            Text(criterion.label)
                .font(.subheadline)
                .foregroundStyle(criterion.isComplete ? .primary : .secondary)
                .lineLimit(1)
        }
    }
}
