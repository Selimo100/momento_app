import SwiftUI
import SwiftData

@main
struct MomentoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Moment.self, MomentPhoto.self])
    }
}
