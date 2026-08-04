import SwiftUI

struct ExportSheetView: View {
    let moment: Moment
    @Binding var albumName: String
    let isExporting: Bool
    let onExport: (ExportScope) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Album Name") {
                    TextField("Album name", text: $albumName)
                }

                Section {
                    exportButton(
                        title: "Export All Photos",
                        subtitle: "\(moment.photos.count) \(moment.photos.count == 1 ? "photo" : "photos")",
                        icon: "photo.stack",
                        scope: .all,
                        disabled: moment.photos.isEmpty
                    )

                    exportButton(
                        title: "Export Favorites Only",
                        subtitle: "\(moment.favoriteCount) \(moment.favoriteCount == 1 ? "favorite" : "favorites")",
                        icon: "heart.fill",
                        scope: .favoritesOnly,
                        disabled: moment.favoriteCount == 0
                    )
                } footer: {
                    Text("Photos will be added to an album in your Apple Photos library. Original photos are never duplicated — existing assets are linked to the album.")
                        .font(.caption)
                }
            }
            .navigationTitle("Export to Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .disabled(isExporting)
                }
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.3)
                            Text("Exporting…")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func exportButton(title: String, subtitle: String, icon: String, scope: ExportScope, disabled: Bool) -> some View {
        Button {
            onExport(scope)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(disabled ? Color.secondary : Color.accentColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(disabled ? .tertiary : .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .disabled(disabled || isExporting)
    }
}
