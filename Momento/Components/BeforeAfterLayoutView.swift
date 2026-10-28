import SwiftUI

/// Two photos side by side, labelled "Before" and "After".
/// Until both are picked, a setup card guides the user.
struct BeforeAfterLayoutView: View {
    let moment: Moment
    let actions: MomentPhotoLayoutActions

    @State private var pickerSlot: BeforeAfterSlot?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let before = moment.beforePhoto, let after = moment.afterPhoto {
                comparison(before: before, after: after)
            } else {
                setupCard
            }
        }
        .sheet(item: $pickerSlot) { slot in
            BeforeAfterPickerSheet(moment: moment, slot: slot) { photo in
                switch slot {
                case .before: actions.setBefore(photo)
                case .after:  actions.setAfter(photo)
                }
            }
        }
    }

    // MARK: Comparison

    private func comparison(before: MomentPhoto, after: MomentPhoto) -> some View {
        SectionCard(insets: 10) {
            HStack(spacing: 10) {
                pane(photo: before, slot: .before)
                pane(photo: after, slot: .after)
            }
        }
    }

    private func pane(photo: MomentPhoto, slot: BeforeAfterSlot) -> some View {
        VStack(spacing: 8) {
            Color.clear
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    AssetThumbnailView(
                        localIdentifier: photo.localIdentifier,
                        targetSize: CGSize(width: 700, height: 933)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(slot.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onTapGesture { actions.openPhoto(photo) }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("\(slot.label) photo")

            Button { pickerSlot = slot } label: {
                Text("Change \(slot.label)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Setup

    private var setupCard: some View {
        SectionCard {
            VStack(spacing: 14) {
                Image(systemName: "rectangle.split.2x1")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.tertiary)

                VStack(spacing: 6) {
                    Text("Choose your before and after photos")
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Text("Pick two photos from this moment to show the change side by side.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    ForEach(BeforeAfterSlot.allCases) { slot in
                        slotButton(slot)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private func slotButton(_ slot: BeforeAfterSlot) -> some View {
        let isSet = slot == .before ? moment.beforePhoto != nil : moment.afterPhoto != nil
        return Button { pickerSlot = slot } label: {
            HStack(spacing: 6) {
                Image(systemName: isSet ? "checkmark.circle.fill" : "plus.circle")
                    .font(.subheadline.weight(.semibold))
                Text(slot.label)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSet ? Color.accentColor : .primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(moment.photos.isEmpty)
    }
}

// MARK: - Slot

enum BeforeAfterSlot: String, CaseIterable, Identifiable {
    case before
    case after

    var id: String { rawValue }

    var label: String {
        switch self {
        case .before: return "Before"
        case .after:  return "After"
        }
    }
}

// MARK: - Picker sheet

/// Simple grid picker used to assign a photo to the Before or After slot.
struct BeforeAfterPickerSheet: View {
    let moment: Moment
    let slot: BeforeAfterSlot
    let onSelect: (MomentPhoto) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(moment.sortedPhotos) { photo in
                        PhotoThumbnailView(
                            photo: photo,
                            isCover: photo.id == moment.coverPhotoId,
                            cornerRadius: 14
                        ) {
                            onSelect(photo)
                            dismiss()
                        }
                        .overlay {
                            if isSelected(photo) {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.accentColor, lineWidth: 3)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Choose \(slot.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func isSelected(_ photo: MomentPhoto) -> Bool {
        switch slot {
        case .before: return moment.beforePhotoId == photo.id
        case .after:  return moment.afterPhotoId == photo.id
        }
    }
}
