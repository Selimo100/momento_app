import SwiftUI
import SwiftData
import PhotosUI
import Photos

struct MomentDetailView: View {
    let moment: Moment
    /// When set, this photo is opened automatically once the view appears
    /// (used by "Surprise Me → Random Best Shot").
    var initialPhoto: MomentPhoto? = nil

    @Environment(\.modelContext) private var context
    @State private var didOpenInitialPhoto = false
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

    @State private var lock = PrivacyLockService.shared
    @State private var showMakePrivateConfirmation = false
    @State private var showLeavePrivateConfirmation = false
    @State private var isAuthenticating = false
    @State private var privacyErrorMessage: String?
    @State private var showPrivacyError = false

    var body: some View {
        detailContent
            .detailNavigationChrome(
                dismiss: { dismiss() },
                menu: { detailMenu }
            )
            .detailSheets(
                showEditSheet: $showEditSheet,
                showTimeCapsuleSheet: $showTimeCapsuleSheet,
                showingExportSheet: $viewModel.showingExportSheet,
                editSheet: { MomentFormView(mode: .edit(moment)) },
                timeCapsuleSheet: { timeCapsuleSheet },
                exportSheet: { exportSheet }
            )
            .detailPhotoPicker(
                showingPhotoPicker: $viewModel.showingPhotoPicker,
                photoPickerItems: $viewModel.photoPickerItems,
                onItemsChanged: loadPhotoPickerItems
            )
            .detailPhotoCover(
                showingPhotoDetail: $viewModel.showingPhotoDetail,
                selectedPhoto: viewModel.selectedPhoto,
                content: { photoDetailView(for: $0) }
            )
            .detailAlerts(
                showExportResult: $viewModel.showExportResult,
                exportResultMessage: viewModel.exportResultMessage,
                showPermissionAlert: $showPermissionAlert,
                permissionMessage: permissionMessage
            )
            .detailConfirmationDialogs(
                showDeleteConfirmation: $showDeleteConfirmation,
                showUnlockEarlyConfirmation: $showUnlockEarlyConfirmation,
                deleteMoment: deleteMoment,
                unlockMoment: unlockMoment
            )
            .onAppear(perform: openInitialPhotoIfNeeded)
            .privacyDialogs(
                showMakePrivate: $showMakePrivateConfirmation,
                showLeavePrivate: $showLeavePrivateConfirmation,
                showError: $showPrivacyError,
                errorMessage: privacyErrorMessage,
                biometryLabel: lock.biometryLabel,
                makePrivate: { Task { await moveToPrivate() } },
                leavePrivate: moveOutOfPrivate
            )
    }

    private func openInitialPhotoIfNeeded() {
        guard let initialPhoto, !didOpenInitialPhoto, !moment.isLocked, !isConcealed else { return }
        didOpenInitialPhoto = true
        viewModel.selectedPhoto = initialPhoto
        viewModel.showingPhotoDetail = true
    }

    /// A private moment may only be rendered inside an authenticated session.
    /// This also covers the case where the app was backgrounded while a private
    /// moment was open.
    private var isConcealed: Bool {
        moment.isPrivate && !lock.isUnlocked
    }

    @ViewBuilder
    private var detailContent: some View {
        if isConcealed {
            concealedContent
        } else {
            unlockedDetailContent
        }
    }

    private var concealedContent: some View {
        ScrollView {
            PrivacyLockedStateView(
                title: "This moment is private",
                message: "Authenticate to view this memory. It stays hidden from your main library either way.",
                actionTitle: "Unlock",
                isAuthenticating: isAuthenticating,
                errorMessage: lock.lastErrorMessage
            ) {
                Task {
                    isAuthenticating = true
                    await lock.unlock()
                    isAuthenticating = false
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var unlockedDetailContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                MomentHeroView(moment: moment)

                capsuleContentView
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                    .background(Color(.systemGroupedBackground))
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
    }

    private var detailMenu: some View {
        Menu {
            Button { showEditSheet = true } label: {
                Label("Edit Moment", systemImage: "pencil")
            }
            if !moment.isTimeCapsule && moment.reminderDate == nil {
                Button { showTimeCapsuleSheet = true } label: {
                    Label("Open Later", systemImage: "clock")
                }
            }
            if moment.isTimeCapsule {
                Button { showUnlockEarlyConfirmation = true } label: {
                    Label("Unlock Early", systemImage: "lock.open")
                }
            }
            if moment.reminderDate != nil {
                Button { clearReminder() } label: {
                    Label("Cancel Reminder", systemImage: "bell.slash")
                }
            }
            if !moment.isLocked {
                Button { prepareExport() } label: {
                    Label("Export to Photos", systemImage: "square.and.arrow.up")
                }
            }
            Divider()
            if moment.isPrivate {
                Button { showLeavePrivateConfirmation = true } label: {
                    Label("Move out of Private", systemImage: "lock.open")
                }
            } else {
                Button { showMakePrivateConfirmation = true } label: {
                    Label("Move to Private", systemImage: "lock")
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

    private var timeCapsuleSheet: some View {
        TimeCapsuleSheetView(moment: moment) { action in
            switch action {
            case .seal(let date):
                sealMoment(unlockDate: date)
            case .remind(let date):
                setReminder(date: date)
            }
            showTimeCapsuleSheet = false
        }
    }

    private var exportSheet: some View {
        ExportSheetView(
            moment: moment,
            albumName: $viewModel.exportAlbumName,
            isExporting: viewModel.isExporting,
            onExport: exportPhotos,
            onCancel: { viewModel.showingExportSheet = false }
        )
        .presentationDetents([.medium, .large])
    }

    private func photoDetailView(for photo: MomentPhoto) -> some View {
        PhotoDetailView(
            moment: moment,
            initialPhoto: photo,
            onFavoriteToggle: { selectedPhoto in
                viewModel.toggleFavorite(selectedPhoto, in: moment, context: context)
            },
            onSetCover: { selectedPhoto in
                viewModel.setCover(selectedPhoto, in: moment, context: context)
            },
            onRemove: { selectedPhoto in
                viewModel.removePhoto(selectedPhoto, from: moment, context: context)
            },
            onSetBefore: setBeforePhoto,
            onSetAfter: setAfterPhoto
        )
    }

    private func loadPhotoPickerItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            await viewModel.loadPickerItems(items, into: moment, context: context)
            viewModel.photoPickerItems = []
        }
    }

    private func exportPhotos(scope: ExportScope) {
        Task {
            await viewModel.export(moment: moment, scope: scope, context: context)
        }
    }

    private func deleteMoment() {
        context.delete(moment)
        try? context.save()
        dismiss()
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
            if let reminderDate = moment.reminderDate {
                reminderBanner(date: reminderDate)
            }
            if !moment.momentDescription.isEmpty {
                descriptionCard
            }
            StoryCardView(moment: moment)
            MomentCompletionCard(moment: moment)
            MomentPhotoSectionView(moment: moment, actions: photoLayoutActions)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Reminder banner

    private func reminderBanner(date: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: accentColorHex))

            VStack(alignment: .leading, spacing: 2) {
                Text("Reminder set")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(DateFormatter.momentDate.string(from: date))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                clearReminder()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(hex: accentColorHex).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private var photoLayoutActions: MomentPhotoLayoutActions {
        MomentPhotoLayoutActions(
            openPhoto: { photo in
                viewModel.selectedPhoto = photo
                viewModel.showingPhotoDetail = true
            },
            addPhotos: checkPermissionsAndAddPhotos,
            setBefore: setBeforePhoto,
            setAfter: setAfterPhoto,
            changeLayout: changeLayout
        )
    }

    private func changeLayout(_ layout: MomentLayoutType) {
        moment.layout = layout
        moment.updatedAt = .now
        try? context.save()
    }

    private func setBeforePhoto(_ photo: MomentPhoto) {
        moment.beforePhotoId = photo.id
        moment.updatedAt = .now
        try? context.save()
    }

    private func setAfterPhoto(_ photo: MomentPhoto) {
        moment.afterPhotoId = photo.id
        moment.updatedAt = .now
        try? context.save()
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
        // Clear any existing reminder when sealing
        TimeCapsuleService.cancelReminderNotification(for: moment)
        moment.reminderDate = nil
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
        TimeCapsuleService.cancelUnlockNotification(for: moment)
        moment.isTimeCapsule = false
        moment.unlockDate = nil
        moment.lockedAt = nil
        moment.updatedAt = .now
        try? context.save()
    }

    private func setReminder(date: Date) {
        moment.reminderDate = date
        moment.updatedAt = .now
        try? context.save()
        Task {
            let granted = await TimeCapsuleService.requestNotificationPermission()
            if granted {
                TimeCapsuleService.scheduleReminderNotification(for: moment)
            }
        }
    }

    // MARK: Privacy

    /// Requires a successful authentication before anything is written.
    private func moveToPrivate() async {
        let result = await lock.authenticate(reason: "Unlock your private moments")
        switch result {
        case .success:
            moment.isPrivate = true
            moment.updatedAt = .now
            try? context.save()
            // Opening the private area from here should not require a second prompt.
            lock.markUnlockedForCurrentSession()
        case .failure(let error):
            privacyErrorMessage = error.message
            showPrivacyError = true
        }
    }

    private func moveOutOfPrivate() {
        moment.isPrivate = false
        moment.updatedAt = .now
        try? context.save()
    }

    private func clearReminder() {
        TimeCapsuleService.cancelReminderNotification(for: moment)
        moment.reminderDate = nil
        moment.updatedAt = .now
        try? context.save()
    }
}

private extension View {
    func detailNavigationChrome<MenuContent: View>(
        dismiss: @escaping () -> Void,
        @ViewBuilder menu: @escaping () -> MenuContent
    ) -> some View {
        navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GlassIconButton(icon: "chevron.left", action: dismiss)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    menu()
                }
            }
    }

    func detailSheets<EditSheet: View, TimeCapsuleSheet: View, ExportSheet: View>(
        showEditSheet: Binding<Bool>,
        showTimeCapsuleSheet: Binding<Bool>,
        showingExportSheet: Binding<Bool>,
        @ViewBuilder editSheet: @escaping () -> EditSheet,
        @ViewBuilder timeCapsuleSheet: @escaping () -> TimeCapsuleSheet,
        @ViewBuilder exportSheet: @escaping () -> ExportSheet
    ) -> some View {
        sheet(isPresented: showEditSheet) {
            editSheet()
        }
        .sheet(isPresented: showTimeCapsuleSheet) {
            timeCapsuleSheet()
        }
        .sheet(isPresented: showingExportSheet) {
            exportSheet()
        }
    }

    func detailPhotoPicker(
        showingPhotoPicker: Binding<Bool>,
        photoPickerItems: Binding<[PhotosPickerItem]>,
        onItemsChanged: @escaping ([PhotosPickerItem]) -> Void
    ) -> some View {
        photosPicker(
            isPresented: showingPhotoPicker,
            selection: photoPickerItems,
            maxSelectionCount: 100,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: photoPickerItems.wrappedValue) { _, items in
            onItemsChanged(items)
        }
    }

    func detailPhotoCover<Content: View>(
        showingPhotoDetail: Binding<Bool>,
        selectedPhoto: MomentPhoto?,
        @ViewBuilder content: @escaping (MomentPhoto) -> Content
    ) -> some View {
        fullScreenCover(isPresented: showingPhotoDetail) {
            if let selectedPhoto {
                content(selectedPhoto)
            }
        }
    }

    func detailAlerts(
        showExportResult: Binding<Bool>,
        exportResultMessage: String?,
        showPermissionAlert: Binding<Bool>,
        permissionMessage: String
    ) -> some View {
        alert("Export Result", isPresented: showExportResult) {
            Button("OK") {}
        } message: {
            Text(exportResultMessage ?? "")
        }
        .alert("Photo Access", isPresented: showPermissionAlert) {
            Button("Open Settings") { PermissionHelpers.openAppSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionMessage)
        }
    }

    func detailConfirmationDialogs(
        showDeleteConfirmation: Binding<Bool>,
        showUnlockEarlyConfirmation: Binding<Bool>,
        deleteMoment: @escaping () -> Void,
        unlockMoment: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            "Delete Moment",
            isPresented: showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteMoment)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the moment and its photo references. Your original photos in Apple Photos are not affected.")
        }
        .confirmationDialog(
            "Unlock this time capsule early?",
            isPresented: showUnlockEarlyConfirmation,
            titleVisibility: .visible
        ) {
            Button("Unlock Early", role: .destructive, action: unlockMoment)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reveal the memory before its scheduled date and remove the seal.")
        }
    }
}

private extension View {
    func privacyDialogs(
        showMakePrivate: Binding<Bool>,
        showLeavePrivate: Binding<Bool>,
        showError: Binding<Bool>,
        errorMessage: String?,
        biometryLabel: String,
        makePrivate: @escaping () -> Void,
        leavePrivate: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            "Move to Private",
            isPresented: showMakePrivate,
            titleVisibility: .visible
        ) {
            Button("Move to Private", action: makePrivate)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This moment will be hidden from your library and only reachable through Private Moments, protected with \(biometryLabel).")
        }
        .confirmationDialog(
            "Move out of Private",
            isPresented: showLeavePrivate,
            titleVisibility: .visible
        ) {
            Button("Move out of Private", action: leavePrivate)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This moment will appear in your normal library again.")
        }
        .alert("Not Unlocked", isPresented: showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
