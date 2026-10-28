import SwiftUI

enum TimeCapsuleAction {
    case seal(Date)
    case remind(Date)
}

struct TimeCapsuleSheetView: View {
    let moment: Moment
    let onConfirm: (TimeCapsuleAction) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    @State private var mode: CapsuleMode = .remind
    @State private var selectedOption: UnlockOption = .thirtyDays
    @State private var customDate: Date = {
        Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    }()

    // MARK: Mode

    enum CapsuleMode: CaseIterable {
        case remind, seal

        var title: String {
            switch self {
            case .remind: return "Remind Me"
            case .seal:   return "Seal Memory"
            }
        }
        var subtitle: String {
            switch self {
            case .remind: return "Stay visible, get notified on the date"
            case .seal:   return "Hide until the date — a surprise for future you"
            }
        }
        var icon: String {
            switch self {
            case .remind: return "bell.fill"
            case .seal:   return "lock.fill"
            }
        }
    }

    // MARK: Date options

    enum UnlockOption: String, CaseIterable, Hashable {
        case thirtyDays = "In 30 Days"
        case endOfYear  = "End of This Year"
        case nextSummer = "Next Summer"
        case custom     = "Custom Date"

        func resolvedDate(now: Date = .now) -> Date? {
            let cal = Calendar.current
            switch self {
            case .thirtyDays:
                return cal.date(byAdding: .day, value: 30, to: now)
            case .endOfYear:
                var components = cal.dateComponents([.year], from: now)
                components.month = 12; components.day = 31; components.hour = 9; components.minute = 0
                return cal.date(from: components)
            case .nextSummer:
                var components = cal.dateComponents([.year], from: now)
                components.month = 6; components.day = 21; components.hour = 9; components.minute = 0
                if let thisYear = cal.date(from: components), thisYear > now { return thisYear }
                components.year = (components.year ?? cal.component(.year, from: now)) + 1
                return cal.date(from: components)
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
                    modeSection
                    Divider()
                    dateSection
                    previewSection
                    confirmButton
                }
                .padding(.horizontal, 20)
                .adaptiveContentWidth(maxWidth: 560, includeHorizontalPadding: false)
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Open Later")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // `cancellationAction` rather than `topBarLeading` so the system
                // pins this to the top of a vertical bar on iPhone Duo.
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                }
            }
        }
    }

    // MARK: Mode picker

    private var modeSection: some View {
        VStack(spacing: 10) {
            ForEach(CapsuleMode.allCases, id: \.title) { capsuleMode in
                modeCard(capsuleMode)
            }
        }
    }

    private func modeCard(_ capsuleMode: CapsuleMode) -> some View {
        let isSelected = mode == capsuleMode
        return Button {
            withAnimation(.spring(response: 0.3)) { mode = capsuleMode }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? Color(hex: accentColorHex).opacity(0.15)
                              : Color(.tertiarySystemGroupedBackground))
                        .frame(width: 44, height: 44)
                    Image(systemName: capsuleMode.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? Color(hex: accentColorHex) : .secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(capsuleMode.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(capsuleMode.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color(hex: accentColorHex) : Color(.tertiaryLabel))
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color(hex: accentColorHex).opacity(0.5) : Color.clear,
                            lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Date section

    private var dateSection: some View {
        VStack(spacing: 10) {
            ForEach(UnlockOption.allCases, id: \.self) { option in
                optionRow(option)
            }
            if selectedOption == .custom {
                customDatePicker
            }
        }
    }

    private func optionRow(_ option: UnlockOption) -> some View {
        let isSelected = selectedOption == option
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedOption = option }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(isSelected ? Color(hex: accentColorHex) : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                    if option != .custom, let resolved = option.resolvedDate() {
                        Text(DateFormatter.momentDate.string(from: resolved))
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
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color(hex: accentColorHex).opacity(0.4) : Color.clear,
                            lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var customDatePicker: some View {
        DatePicker(
            "",
            selection: $customDate,
            in: minimumCustomDate...,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Preview

    private var previewSection: some View {
        HStack(spacing: 12) {
            Image(systemName: mode == .remind ? "bell.badge" : "clock.badge.checkmark")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: accentColorHex))

            VStack(alignment: .leading, spacing: 2) {
                Text(mode == .remind ? "Notification on" : "Will reopen on")
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

    // MARK: Confirm button

    private var confirmButton: some View {
        Button {
            let action: TimeCapsuleAction = mode == .seal
                ? .seal(resolvedDate)
                : .remind(resolvedDate)
            onConfirm(action)
        } label: {
            Label(
                mode == .remind ? "Set Reminder" : "Seal this Memory",
                systemImage: mode == .remind ? "bell.fill" : "lock.fill"
            )
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
