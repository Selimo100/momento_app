import SwiftUI
import SwiftData

/// The authenticated home for private moments.
///
/// Nothing is rendered until `PrivacyLockService` reports an unlocked session,
/// and the session is cleared whenever the app leaves the foreground.
struct PrivateMomentsView: View {
    @Query(sort: \Moment.createdAt, order: .reverse) private var allMoments: [Moment]

    @State private var lock = PrivacyLockService.shared
    @State private var isAuthenticating = false
    @State private var didAutoPrompt = false
    @State private var searchText = ""

    private var privateMoments: [Moment] {
        let hidden = allMoments.filter(\.isPrivate)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return hidden }
        return hidden.filter { moment in
            moment.title.localizedCaseInsensitiveContains(query)
                || moment.momentDescription.localizedCaseInsensitiveContains(query)
                || (moment.story ?? "").localizedCaseInsensitiveContains(query)
                || (moment.locationName ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        Group {
            if lock.isUnlocked {
                unlockedContent
            } else {
                lockedContent
            }
        }
        .navigationTitle("Private Moments")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .task {
            // Offer the prompt once when the area is opened.
            guard !didAutoPrompt, !lock.isUnlocked else { return }
            didAutoPrompt = true
            await authenticate()
        }
        .onChange(of: lock.isUnlocked) { _, unlocked in
            if !unlocked {
                searchText = ""
                didAutoPrompt = false
            }
        }
    }

    // MARK: Locked

    private var lockedContent: some View {
        ScrollView {
            PrivacyLockedStateView(
                title: "Private Moments",
                message: "These memories are kept out of your main library. Authenticate to view them.",
                actionTitle: "Unlock",
                isAuthenticating: isAuthenticating,
                errorMessage: lock.lastErrorMessage
            ) {
                Task { await authenticate() }
            }
            .padding(20)
            .adaptiveContentWidth(maxWidth: 480, includeHorizontalPadding: false)
        }
    }

    // MARK: Unlocked

    @ViewBuilder
    private var unlockedContent: some View {
        if allMoments.contains(where: \.isPrivate) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(privateMoments) { moment in
                        NavigationLink(destination: MomentDetailView(moment: moment)) {
                            MomentCardView(moment: moment)
                        }
                        .buttonStyle(.plain)
                    }

                    if privateMoments.isEmpty {
                        Text("No private moments match your search.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    }
                }
                .adaptiveContentWidth()
                .padding(.vertical, 16)
            }
            .searchable(text: $searchText, prompt: "Search private moments")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lock", systemImage: "lock.fill") {
                        withAnimation(.easeInOut(duration: 0.2)) { lock.lock() }
                    }
                }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "lock.open")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tertiary)

            Text("No private moments yet")
                .font(.system(size: 18, weight: .semibold))

            Text("Open any moment and choose \"Move to Private\" to keep it here, hidden from your main library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

            Spacer()
        }
        .adaptiveContentWidth(maxWidth: 480, includeHorizontalPadding: false)
    }

    // MARK: Actions

    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        await lock.unlock()
        isAuthenticating = false
    }
}
