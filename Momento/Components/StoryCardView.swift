import SwiftUI
import MapKit

struct StoryCardView: View {
    let moment: Moment

    private var hasContent: Bool {
        moment.mood != nil ||
        moment.story != nil ||
        moment.people != nil ||
        moment.locationName != nil ||
        moment.notes != nil
    }

    var body: some View {
        if hasContent {
            SectionCard {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    if let mood = moment.mood {
                        MoodChipView(mood: mood)
                    }

                    if let story = moment.story {
                        Text(story)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if moment.people != nil || moment.locationName != nil {
                        VStack(alignment: .leading, spacing: 10) {
                            if let people = moment.people {
                                StoryDetailRow(icon: "person.2", text: people)
                            }
                            if let location = moment.locationName {
                                StoryDetailRow(icon: "mappin.and.ellipse", text: location)
                            }
                            if let lat = moment.locationLatitude, let lon = moment.locationLongitude {
                                LocationPreviewMap(latitude: lat, longitude: lon)
                            }
                        }
                    }

                    if let notes = moment.notes {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var header: some View {
        Text("Story")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

private struct LocationPreviewMap: View {
    let latitude: Double
    let longitude: Double

    @State private var camera: MapCameraPosition

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        )))
    }

    var body: some View {
        Map(position: $camera, interactionModes: []) {
            Marker("", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                .tint(.red)
        }
        .frame(height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .allowsHitTesting(false)
    }
}

private struct StoryDetailRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
