import SwiftUI
import SwiftData

struct MomentFormView: View {
    enum Mode {
        case create
        case edit(Moment)
    }

    let mode: Mode
    var onSave: ((Moment) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var momentDescription = ""
    @State private var showValidationError = false

    @State private var hasDate = false
    @State private var isDateRange = false
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now

    @State private var layoutType: MomentLayoutType = .story
    @State private var mood = ""
    @State private var story = ""
    @State private var people = ""
    @State private var locationName = ""
    @State private var locationLatitude: Double?
    @State private var locationLongitude: Double?
    @State private var showLocationPicker = false
    @State private var showContactPicker = false
    @State private var notes = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(.body)

                    TextField("Description", text: $momentDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.body)
                } footer: {
                    if showValidationError {
                        Text("Please enter a title.")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Toggle("Set a date", isOn: $hasDate.animation())

                    if hasDate {
                        DatePicker("Start date", selection: $startDate, displayedComponents: .date)

                        Toggle("Date range", isOn: $isDateRange.animation())

                        if isDateRange {
                            DatePicker(
                                "End date",
                                selection: $endDate,
                                in: startDate...,
                                displayedComponents: .date
                            )
                        }
                    }
                } header: {
                    Text("When")
                } footer: {
                    if hasDate && isDateRange {
                        Text("A date range lets you capture a period, like a trip or an event.")
                            .font(.caption)
                    }
                }

                Section {
                    LayoutTypePicker(selection: $layoutType)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } header: {
                    Text("Layout")
                } footer: {
                    Text("Choose how the photos of this moment are presented.")
                        .font(.caption)
                }

                Section {
                    TextField("Mood", text: $mood)
                        .font(.body)

                    TextField("What made this moment special?", text: $story, axis: .vertical)
                        .lineLimit(3...8)
                        .font(.body)
                } header: {
                    Text("Story")
                }

                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "person.2")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        TextField("Who was there?", text: $people)
                            .font(.body)

                        Button {
                            showContactPicker = true
                        } label: {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.body)
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                    }
                    .sheet(isPresented: $showContactPicker) {
                        ContactPickerView { names in
                            let joined = names.joined(separator: ", ")
                            if people.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                people = joined
                            } else {
                                people += ", " + joined
                            }
                        }
                    }

                    Button {
                        showLocationPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)

                            if locationName.isEmpty {
                                Text("Where did it happen?")
                                    .font(.body)
                                    .foregroundStyle(Color(.placeholderText))
                            } else {
                                Text(locationName)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            if !locationName.isEmpty {
                                Button {
                                    locationName = ""
                                    locationLatitude = nil
                                    locationLongitude = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.body)
                                }
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showLocationPicker) {
                        LocationPickerView(
                            locationName: $locationName,
                            latitude: $locationLatitude,
                            longitude: $locationLongitude
                        )
                    }

                    TextField("Small things you want to remember...", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                        .font(.body)
                } header: {
                    Text("Details")
                }
            }
            .navigationTitle(isEditing ? "Edit Moment" : "New Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { prefill() }
    }

    private func prefill() {
        if case .edit(let moment) = mode {
            title = moment.title
            momentDescription = moment.momentDescription
            if let start = moment.startDate {
                hasDate = true
                startDate = start
                if let end = moment.endDate {
                    isDateRange = true
                    endDate = end
                }
            }
            layoutType = moment.layout
            mood = moment.mood ?? ""
            story = moment.story ?? ""
            people = moment.people ?? ""
            locationName = moment.locationName ?? ""
            locationLatitude = moment.locationLatitude
            locationLongitude = moment.locationLongitude
            notes = moment.notes ?? ""
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showValidationError = true
            return
        }

        let resolvedStart: Date? = hasDate ? startDate : nil
        let resolvedEnd: Date? = (hasDate && isDateRange) ? endDate : nil

        switch mode {
        case .create:
            let moment = Moment(
                title: trimmed,
                startDate: resolvedStart,
                endDate: resolvedEnd,
                momentDescription: momentDescription
            )
            moment.layout = layoutType
            moment.mood = mood.trimmedOrNil
            moment.story = story.trimmedOrNil
            moment.people = people.trimmedOrNil
            moment.locationName = locationName.trimmedOrNil
            moment.locationLatitude = locationLatitude
            moment.locationLongitude = locationLongitude
            moment.notes = notes.trimmedOrNil
            context.insert(moment)
            try? context.save()
            dismiss()
            onSave?(moment)

        case .edit(let moment):
            moment.title = trimmed
            moment.momentDescription = momentDescription
            moment.startDate = resolvedStart
            moment.endDate = resolvedEnd
            moment.layout = layoutType
            moment.mood = mood.trimmedOrNil
            moment.story = story.trimmedOrNil
            moment.people = people.trimmedOrNil
            moment.locationName = locationName.trimmedOrNil
            moment.locationLatitude = locationLatitude
            moment.locationLongitude = locationLongitude
            moment.notes = notes.trimmedOrNil
            moment.updatedAt = .now
            try? context.save()
            dismiss()
        }
    }
}
