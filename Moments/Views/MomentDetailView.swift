import SwiftUI
import SwiftData
import PhotosUI
import Photos

struct MomentDetailView: View {
    let moment: Moment

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("albumPrefix") private var albumPrefix = "Momento –"
    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    @State private var viewModel = MomentDetailViewModel()
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showPermissionAlert = false
    @State private var permissionMessage = ""
    @State private var showTimeCapsuleSheet = false
    @State private var showUnlockEarlyConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                MomentHeroView(moment: moment)
                    .ignoresSafeArea(edges: .top)

                capsuleContentView
                    .padding(.top, 32)
                    .padding(.bottom, 100)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 24,
                            style: .continuous
                        )
                    )
                    .padding(.top, -24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GlassIconButton(icon: "chevron.left") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditSheet = true } label: {
                        Label("Edit Moment", systemImage: "pencil")
                    }
                    if !moment.isTimeCapsule {
                        Button { showTimeCapsuleSheet = true } label: {
                            Label("Open Later", systemImage: "lock")
                        }
                    } else {
                        Button { showUnlockEarlyConfirmation = true } label: {
                            Label("Unlock Early", systemImage: "lock.open")
                        }
                    }
                    if !moment.isLocked {
                        Button { prepareExport() } label: {
                            Label("Export to Photos", systemImage: "square.and.arrow.up")
                        }
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Moment", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular, in: Circle())
                }
            }
        }
        // MARK: Sheets & Pickers
        .sheet(isPresented: $showEditSheet) {
            MomentFormView(mode: .edit(moment))
        }
        .sheet(isPresented: $showTimeCapsuleSheet) {
            TimeCapsuleSheetView(moment: moment) { date in
                sealMoment(unlockDate: date)
                showTimeCapsuleSheet = false
            }
        }
        .photosPicker(
            isPresented: $viewModel.showingPhotoPicker,
            selection: $viewModel.photoPickerItems,
            maxSelectionCount: 100,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: viewModel.photoPickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                await viewModel.loadPickerItems(items, into: moment, context: context)
                viewModel.photoPickerItems = []
            }
        }
        .sheet(isPresented: $viewModel.showingExportSheet) {
            ExportSheetView(
                moment: moment,
                albumName: $viewModel.exportAlbumName,
                isExporting: viewModel.isExporting,
                onExport: { scope in
                    Task { await viewModel.export(moment: moment, scope: scope, context: context) }
                },
                onCancel: { viewModel.showingExportSheet = false }
            )
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $viewModel.showingPhotoDetail) {
            if let photo = viewModel.selectedPhoto {
                PhotoDetailView(
                    moment: moment,
                    initialPhoto: photo,
                    onFavoriteToggle: { p in
                        viewModel.toggleFavorite(p, in: moment, context: context)
                    },
                    onSetCover: { p in
                        viewModel.setCover(p, in: moment, context: context)
                    },
                    onRemove: { p in
                        viewModel.removePhoto(p, from: moment, context: context)
                    }
                )
            }
        }
        // MARK: Alerts
        .alert("Export Result", isPresented: $viewModel.showExportResult) {
            Button("OK") {}
        } message: {
            Text(viewModel.exportResultMessage ?? "")
        }
        .alert("Photo Access", isPresented: $showPermissionAlert) {
            Button("Open Settings") { PermissionHelpers.openAppSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionMessage)
        }
        .confirmationDialog(
            "Delete Moment",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                context.delete(moment)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the moment and its photo references. Your original photos in Apple Photos are not affected.")
        }
        .confirmationDialog(
            "Unlock this time capsule early?",
            isPresented: $showUnlockEarlyConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unlock Early", role: .destructive) {
                unlockMoment()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reveal the memory before its scheduled date and remove the seal.")
        }
    }

    // MARK: Conditional content

    @ViewBuilder
    private var capsuleContentView: some View {
        if moment.isLocked {
            TimeCapsuleLockedView(moment: moment) {
                showUnlockEarlyConfirmation = true
            }
        } else if moment.isReadyToReopen {
            TimeCapsuleReadyView(moment: moment) {
                unlockMoment()
            }
        } else {
            contentStack
        }
    }

    // MARK: Normal content

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !moment.momentDescription.isEmpty {
                descriptionCard
            }
            StoryCardView(moment: moment)
            MomentCompletionCard(moment: moment)
            photosSection
        }
        .padding(.horizontal, 16)
    }

    // MARK: Description

    private var descriptionCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("About this moment")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(moment.momentDescription)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            photosSectionHeader

            if moment.photos.isEmpty {
                emptyPhotosCard
            } else {
                SectionCard(insets: 10) {
                    PhotoGridView(
                        photos: moment.photos,
                        coverPhotoId: moment.coverPhotoId
                    ) { photo in
                        viewModel.selectedPhoto = photo
                        viewModel.showingPhotoDetail = true
                    }
                }
            }
        }
    }

    private var photosSectionHeader: some View {
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

            if moment.favoriteCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.pink)
                    Text("\(moment.favoriteCount)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 6)
            }

            Button {
                checkPermissionsAndAddPhotos()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: accentColorHex))
                    .frame(width: 32, height: 32)
                    .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            }
        }
    }

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

                PrimaryButton("Add Photos", icon: "plus") {
                    checkPermissionsAndAddPhotos()
                }
            }
            .padding(.vertical, 20)
        }
    }

    // MARK: Actions

    private func checkPermissionsAndAddPhotos() {
        let status = PhotoLibraryService.shared.authorizationStatus
        switch status {
        case .denied, .restricted:
            permissionMessage = PermissionHelpers.photoLibraryAccessDescription
            showPermissionAlert = true
        case .notDetermined:
            Task {
                let granted = await PhotoLibraryService.shared.requestAuthorization()
                if granted == .authorized || granted == .limited {
                    viewModel.showingPhotoPicker = true
                } else {
                    permissionMessage = PermissionHelpers.photoLibraryAccessDescription
                    showPermissionAlert = true
                }
            }
        default:
            viewModel.showingPhotoPicker = true
        }
    }

    private func prepareExport() {
        guard !moment.photos.isEmpty else {
            viewModel.exportResultMessage = "This moment has no photos to export."
            viewModel.showExportResult = true
            return
        }
        viewModel.exportAlbumName = viewModel.defaultAlbumName(for: moment, prefix: albumPrefix)
        viewModel.showingExportSheet = true
    }

    private func sealMoment(unlockDate: Date) {
        moment.isTimeCapsule = true
        moment.unlockDate = unlockDate
        moment.lockedAt = .now
        moment.updatedAt = .now
        try? context.save()
        Task {
            let granted = await TimeCapsuleService.requestNotificationPermission()
            if granted {
                TimeCapsuleService.scheduleUnlockNotification(for: moment)
            }
        }
    }

    private func unlockMoment() {
        TimeCapsuleService.cancelNotification(for: moment)
        moment.isTimeCapsule = false
        moment.unlockDate = nil
        moment.lockedAt = nil
        moment.updatedAt = .now
        try? context.save()
    }
}
