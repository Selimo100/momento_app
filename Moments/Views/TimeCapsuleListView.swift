import SwiftUI
import SwiftData

struct TimeCapsuleListView: View {
    @Query(sort: \Moment.createdAt, order: .reverse) private var allMoments: [Moment]
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    /// Private moments stay out of this tab as well.
    private var visibleMoments: [Moment] { allMoments.filter { !$0.isPrivate } }

    private var readyMoments: [Moment]   { visibleMoments.filter { $0.isReadyToReopen } }
    private var lockedMoments: [Moment]  { visibleMoments.filter { $0.isLocked } }
    private var reminderMoments: [Moment] { visibleMoments.filter { $0.reminderDate != nil && !$0.isTimeCapsule } }
    private var hasAnyCapsules: Bool { !readyMoments.isEmpty || !lockedMoments.isEmpty || !reminderMoments.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if hasAnyCapsules {
                    capsuleList
                } else {
                    emptyState
                }
            }
            .navigationTitle("Time Capsule")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: Main list

    private var capsuleList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !readyMoments.isEmpty {
                    readySection
                }
                if !reminderMoments.isEmpty {
                    remindersSection
                }
                if !lockedMoments.isEmpty {
                    lockedSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Ready to reopen

    private var readySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Ready to Reopen",
                icon: "gift.fill",
                color: Color(hex: accentColorHex)
            )

            ForEach(readyMoments) { moment in
                NavigationLink(destination: MomentDetailView(moment: moment)) {
                    MomentCardView(moment: moment)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Reminders (visible, just notified)

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Reminders", icon: "bell.fill", color: Color(hex: accentColorHex))

            ForEach(reminderMoments) { moment in
                NavigationLink(destination: MomentDetailView(moment: moment)) {
                    reminderRow(moment)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func reminderRow(_ moment: Moment) -> some View {
        HStack(spacing: 14) {
            // Thumbnail — fully visible
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(width: 64, height: 64)

                if let cover = moment.coverPhoto {
                    AssetThumbnailView(
                        localIdentifier: cover.localIdentifier,
                        targetSize: CGSize(width: 128, height: 128)
                    )
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.tertiary)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(moment.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let reminderDate = moment.reminderDate {
                    Label(
                        DateFormatter.momentDate.string(from: reminderDate),
                        systemImage: "bell"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: Sealed (locked)

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Sealed",
                icon: "lock.fill",
                color: .secondary
            )

            ForEach(lockedMoments) { moment in
                NavigationLink(destination: MomentDetailView(moment: moment)) {
                    lockedRow(moment)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func lockedRow(_ moment: Moment) -> some View {
        HStack(spacing: 14) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(width: 64, height: 64)

                if let cover = moment.coverPhoto {
                    AssetThumbnailView(
                        localIdentifier: cover.localIdentifier,
                        targetSize: CGSize(width: 128, height: 128)
                    )
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .blur(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
                }

                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(moment.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let unlockDate = moment.unlockDate {
                    Label(
                        "Opens \(DateFormatter.momentDate.string(from: unlockDate))",
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let lockedAt = moment.lockedAt {
                    Text("Sealed \(DateFormatter.momentShort.string(from: lockedAt))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            daysRemainingBadge(moment)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func daysRemainingBadge(_ moment: Moment) -> some View {
        if let unlockDate = moment.unlockDate {
            let days = Calendar.current.dateComponents([.day], from: .now, to: unlockDate).day ?? 0
            VStack(spacing: 2) {
                Text("\(max(days, 1))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(days == 1 ? "day" : "days")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44)
        }
    }

    // MARK: Section header

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.horizontal, 4)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: 100, height: 100)
                    Circle()
                        .stroke(Color(.separator).opacity(0.4), lineWidth: 1)
                        .frame(width: 100, height: 100)
                    Image(systemName: "hourglass")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.tertiary)
                }

                VStack(spacing: 8) {
                    Text("No Time Capsules")
                        .font(.title3.weight(.semibold))

                    Text("Seal a moment to open it in the future as a surprise. Open it from the moment's menu.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()
        }
    }
}
