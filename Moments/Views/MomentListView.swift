import SwiftUI
import SwiftData

struct MomentListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Moment.createdAt, order: .reverse) private var moments: [Moment]

    @State private var viewModel = MomentListViewModel()
    @State private var momentToDelete: Moment?
    @State private var momentToEdit: Moment?
    @State private var showDeleteConfirmation = false
    @State private var navigateToNewMoment: Moment?

    @AppStorage("accentColorHex") private var accentColorHex = "a0c1b9"

    // MARK: Computed

    private var readyMoments: [Moment] {
        moments.filter { $0.isReadyToReopen }
    }

    var body: some View {
        NavigationStack {
            Group {
                if moments.isEmpty {
                    emptyState
                } else {
                    momentGrid
                }
            }
            .navigationTitle("Momento")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateSheet) {
                MomentFormView(mode: .create) { newMoment in
                    navigateToNewMoment = newMoment
                }
            }
            .sheet(item: $momentToEdit) { moment in
                MomentFormView(mode: .edit(moment))
            }
            .confirmationDialog("Delete Moment", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let moment = momentToDelete {
                        viewModel.deleteMoment(moment, context: context)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the moment and all its photo references. Original photos in Apple Photos are not affected.")
            }
            .navigationDestination(item: $navigateToNewMoment) { moment in
                MomentDetailView(moment: moment)
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: "photo.on.rectangle.angled",
                title: "No Moments Yet",
                message: "Create your first moment to start collecting photos.",
                actionTitle: "Create a Moment"
            ) {
                viewModel.showingCreateSheet = true
            }
            Spacer()
        }
    }

    // MARK: Moment grid

    private var momentGrid: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !readyMoments.isEmpty {
                    readyToReopenBanner
                        .padding(.top, 4)
                }

                ForEach(moments) { moment in
                    NavigationLink(destination: MomentDetailView(moment: moment)) {
                        MomentCardView(moment: moment)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            momentToEdit = moment
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            momentToDelete = moment
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Ready-to-reopen banner

    private var readyToReopenBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Ready to Reopen", systemImage: "gift")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(hex: accentColorHex))
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, 4)

            ForEach(readyMoments) { moment in
                NavigationLink(destination: MomentDetailView(moment: moment)) {
                    readyBannerCard(moment)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(hex: accentColorHex).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: accentColorHex).opacity(0.2), lineWidth: 1)
        )
    }

    private func readyBannerCard(_ moment: Moment) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: accentColorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "gift.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: accentColorHex))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(moment.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("Tap to reopen this memory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
