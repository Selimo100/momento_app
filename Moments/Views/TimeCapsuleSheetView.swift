import SwiftUI

struct TimeCapsuleSheetView: View {
    let moment: Moment
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    @State private var selectedOption: UnlockOption = .thirtyDays
    @State private var customDate: Date = {
        Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    }()

    // MARK: Options

    enum UnlockOption: String, CaseIterable, Hashable {
        case thirtyDays = "In 30 Days"
        case endOfYear = "End of This Year"
        case nextSummer = "Next Summer"
        case custom = "Custom Date"

        func resolvedDate(now: Date = .now) -> Date? {
            let cal = Calendar.current
            switch self {
            case .thirtyDays:
                return cal.date(byAdding: .day, value: 30, to: now)
            case .endOfYear:
                var c = cal.dateComponents([.year], from: now)
                c.month = 12; c.day = 31; c.hour = 9; c.minute = 0
                return cal.date(from: c)
            case .nextSummer:
                var c = cal.dateComponents([.year], from: now)
                c.month = 6; c.day = 21; c.hour = 9; c.minute = 0
                let thisYearSummer = cal.date(from: c)
                if let d = thisYearSummer, d > now { return d }
                c.year = (c.year ?? 2025) + 1
                return cal.date(from: c)
            case .custom:
                return nil
            }
        }

        var icon: String {
            switch self {
            case .thirtyDays:  return "clock"
            case .endOfYear:   return "calendar.badge.clock"
            case .nextSummer:  return "sun.max"
            case .custom:      return "calendar"
            }
        }
    }

    // MARK: Helpers

    private var minimumCustomDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    }

    private var resolvedDate: Date {
        if selectedOption == .custom { return customDate }
        return selectedOption.resolvedDate() ?? customDate
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    optionsSection
                    if selectedOption == .custom {
                        customDateSection
                    }
                    previewSection
                    sealButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Open Later")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                Text("Seal this memory")
                    .font(.title3.weight(.semibold))
                Text("Choose when this moment will reopen. Until then, it stays sealed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.top, 8)
    }

    private var optionsSection: some View {
        VStack(spacing: 10) {
            ForEach(UnlockOption.allCases, id: \.self) { option in
                optionRow(option)
            }
        }
    }

    private func optionRow(_ option: UnlockOption) -> some View {
        let isSelected = selectedOption == option
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedOption = option
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color(hex: accentColorHex) : .secondary)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                    if option != .custom, let d = option.resolvedDate() {
                        Text(DateFormatter.momentDate.string(from: d))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: accentColorHex))
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? Color(hex: accentColorHex).opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var customDateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick a date")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, 4)

            DatePicker(
                "",
                selection: $customDate,
                in: minimumCustomDate...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var previewSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: accentColorHex))

            VStack(alignment: .leading, spacing: 2) {
                Text("Will reopen on")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(DateFormatter.momentDate.string(from: resolvedDate))
                    .font(.subheadline.weight(.semibold))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(hex: accentColorHex).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var sealButton: some View {
        Button {
            onConfirm(resolvedDate)
        } label: {
            Label("Seal this Memory", systemImage: "lock.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: accentColorHex))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.bottom, 8)
    }
}
