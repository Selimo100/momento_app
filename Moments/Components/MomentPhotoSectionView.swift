import SwiftUI

/// Photo actions a layout can trigger. Kept in one value so every layout
/// gets the same capabilities without threading six closures around.
struct MomentPhotoLayoutActions {
    var openPhoto: (MomentPhoto) -> Void
    var addPhotos: () -> Void
    var setBefore: (MomentPhoto) -> Void = { _ in }
    var setAfter: (MomentPhoto) -> Void = { _ in }
    var changeLayout: (MomentLayoutType) -> Void = { _ in }
}

/// Owns the "Photos" section of the detail screen and picks the layout
/// matching `moment.layout`. The detail view stays free of layout branching.
struct MomentPhotoSectionView: View {
    let moment: Moment
    let actions: MomentPhotoLayoutActions

    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if moment.photos.isEmpty {
                emptyPhotosCard
            } else {
                layoutView
            }
        }
    }

    // MARK: Layout switch

    @ViewBuilder
    private var layoutView: some View {
        switch moment.layout {
        case .story:
            StoryPhotoLayoutView(moment: moment, actions: actions)
        case .timeline:
            TimelinePhotoLayoutView(moment: moment, actions: actions)
        case .collage:
            CollagePhotoLayoutView(moment: moment, actions: actions)
        case .favoritesOnly:
            FavoritesOnlyLayoutView(moment: moment, actions: actions)
        case .photoDump:
            PhotoDumpLayoutView(moment: moment, actions: actions)
        case .beforeAfter:
            BeforeAfterLayoutView(moment: moment, actions: actions)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 4) {
            Text("Photos")
                .font(.system(size: 17, weight: .semibold))

            Text("·")
                .foregroundStyle(.tertiary)
                .font(.system(size: 17))

            Text("\(moment.photos.count)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer()

            layoutBadge

            if moment.favoriteCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.pink)
                    Text("\(moment.favoriteCount)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 4)
                .accessibilityLabel("\(moment.favoriteCount) favorites")
            }

            Button(action: actions.addPhotos) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: accentColorHex))
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            }
            .padding(.leading, 4)
            .accessibilityLabel("Add photos")
        }
    }

    /// Tap the badge to switch layout without going through the edit form.
    private var layoutBadge: some View {
        Menu {
            Picker("Layout", selection: layoutSelection) {
                ForEach(MomentLayoutType.allCases) { type in
                    Label(type.label, systemImage: type.icon).tag(type)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: moment.layout.icon)
                    .font(.caption2.weight(.semibold))
                Text(moment.layout.label)
                    .font(.caption.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
        }
        .accessibilityLabel("Layout: \(moment.layout.label)")
        .accessibilityHint("Change how these photos are shown")
    }

    private var layoutSelection: Binding<MomentLayoutType> {
        Binding(
            get: { moment.layout },
            set: { newValue in
                guard newValue != moment.layout else { return }
                withAnimation(.snappy(duration: 0.25)) { actions.changeLayout(newValue) }
            }
        )
    }

    // MARK: Empty state

    private var emptyPhotosCard: some View {
        SectionCard {
            VStack(spacing: 16) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.tertiary)

                VStack(spacing: 6) {
                    Text("No photos yet")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Add your favorite pictures to bring this moment to life.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                PrimaryButton("Add Photos", icon: "plus", action: actions.addPhotos)
            }
            .padding(.vertical, 20)
        }
    }
}
