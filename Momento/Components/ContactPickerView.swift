import SwiftUI
@preconcurrency import ContactsUI

struct ContactPickerView: UIViewControllerRepresentable {
    // Bound to the presenting view's sheet flag. Using an explicit binding
    // instead of `@Environment(\.dismiss)` — inside a representable the
    // environment action can resolve to the enclosing form sheet and dismiss
    // the whole editor instead of just the picker.
    @Binding var isPresented: Bool
    var onSelect: ([String]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {
        context.coordinator.parent = self
    }

    // @unchecked Sendable: UIKit guarantees delegate methods are called on the
    // main thread.
    final class Coordinator: NSObject, CNContactPickerDelegate, @unchecked Sendable {
        var parent: ContactPickerView

        init(parent: ContactPickerView) {
            self.parent = parent
        }

        // Single tap on a contact row.
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            finish(with: [contact])
        }

        // Multi-select: implementing this enables the checkmarks + Done button.
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            finish(with: contacts)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            finish(with: [])
        }

        private func finish(with contacts: [CNContact]) {
            let names = contacts.compactMap { CNContactFormatter.string(from: $0, style: .fullName) }
            let parent = self.parent
            Task { @MainActor in
                if !names.isEmpty {
                    parent.onSelect(names)
                }
                parent.isPresented = false
            }
        }
    }
}
