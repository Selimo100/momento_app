import SwiftUI
import Contacts

/// Native SwiftUI contact picker.
///
/// Replaces `CNContactPickerViewController`: presented as a sheet from inside
/// the moment editor, the UIKit picker's own dismissal tears down the editor
/// sheet along with it, silently discarding the moment being written.
struct ContactPickerView: View {
    @Binding var isPresented: Bool
    var onSelect: ([String]) -> Void

    @State private var contacts: [ContactEntry] = []
    @State private var selection: Set<String> = []
    @State private var search = ""
    @State private var status: LoadStatus = .loading

    private enum LoadStatus {
        case loading
        case denied
        case loaded
    }

    struct ContactEntry: Identifiable, Hashable {
        let id: String
        let name: String
    }

    private var filtered: [ContactEntry] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch status {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .denied:
                    ContentUnavailableView {
                        Label("No Access to Contacts", systemImage: "person.crop.circle.badge.exclamationmark")
                    } description: {
                        Text("Allow contacts access in Settings to add people from your address book. You can always type names by hand.")
                    }
                case .loaded:
                    List(filtered) { contact in
                        Button {
                            toggle(contact)
                        } label: {
                            HStack {
                                Text(contact.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selection.contains(contact.id) {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(
                        text: $search,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search Contacts"
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .overlay {
                        if filtered.isEmpty {
                            if contacts.isEmpty {
                                ContentUnavailableView(
                                    "No Contacts",
                                    systemImage: "person.crop.circle",
                                    description: Text("You can type names by hand in the moment instead.")
                                )
                            } else {
                                ContentUnavailableView.search(text: search)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { confirm() }
                        .fontWeight(.semibold)
                        .disabled(selection.isEmpty)
                }
            }
        }
        .task { await load() }
    }

    private func toggle(_ contact: ContactEntry) {
        if selection.contains(contact.id) {
            selection.remove(contact.id)
        } else {
            selection.insert(contact.id)
        }
    }

    private func confirm() {
        let names = contacts.filter { selection.contains($0.id) }.map(\.name)
        if !names.isEmpty { onSelect(names) }
        isPresented = false
    }

    private func load() async {
        let store = CNContactStore()
        let granted = (try? await store.requestAccess(for: .contacts)) ?? false
        guard granted else {
            status = .denied
            return
        }

        let entries = await Task.detached(priority: .userInitiated) { () -> [ContactEntry] in
            let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
            let request = CNContactFetchRequest(keysToFetch: keys)
            request.sortOrder = .userDefault
            var result: [ContactEntry] = []
            try? CNContactStore().enumerateContacts(with: request) { contact, _ in
                guard let name = CNContactFormatter.string(from: contact, style: .fullName),
                      !name.isEmpty else { return }
                result.append(ContactEntry(id: contact.identifier, name: name))
            }
            return result
        }.value

        contacts = entries
        status = .loaded
    }
}
