import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var locationName: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedItem: MKMapItem?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mapLayer
                searchOverlay
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let item = selectedItem {
                    confirmBar(item: item)
                }
            }
        }
    }

    // MARK: Map

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            if let item = selectedItem {
                Marker(item.name ?? "Location", coordinate: item.location.coordinate)
                    .tint(.red)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Search overlay

    private var searchOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            searchBar
            if !searchResults.isEmpty {
                resultsList
            }
        }
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.body)

            TextField("Search for a place...", text: $searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit { triggerSearch() }
                .onChange(of: searchText) { _, value in
                    if value.isEmpty {
                        searchResults = []
                        searchTask?.cancel()
                    } else {
                        scheduleSearch()
                    }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    searchTask?.cancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    private var resultsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(searchResults.prefix(6).enumerated()), id: \.offset) { index, item in
                Button {
                    select(item)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Place")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if let sub = subtitle(for: item) {
                                Text(sub)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                if index < min(searchResults.count, 6) - 1 {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }

    // MARK: Confirm bar

    @ViewBuilder
    private func confirmBar(item: MKMapItem) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 3) {
                Text(item.name ?? "Selected Location")
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                if let sub = subtitle(for: item) {
                    Text(sub)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Button(action: confirmSelection) {
                Text("Use This Location")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(.regularMaterial)
    }

    // MARK: Actions

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(380))
            guard !Task.isCancelled else { return }
            triggerSearch()
        }
    }

    private func triggerSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            guard let response = try? await MKLocalSearch(request: request).start() else { return }
            searchResults = response.mapItems
        }
    }

    private func select(_ item: MKMapItem) {
        selectedItem = item
        searchText = ""
        searchResults = []
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: item.location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }

    private func confirmSelection() {
        guard let item = selectedItem else { return }
        locationName = item.name ?? subtitle(for: item) ?? ""
        latitude = item.location.coordinate.latitude
        longitude = item.location.coordinate.longitude
        dismiss()
    }

    private func subtitle(for item: MKMapItem) -> String? {
        item.addressRepresentations?.cityWithContext
            ?? item.address?.shortAddress
            ?? item.address?.fullAddress.trimmedOrNil
    }
}
