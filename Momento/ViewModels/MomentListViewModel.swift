import SwiftUI
import SwiftData
import Photos

@MainActor
@Observable
final class MomentListViewModel {
    var showingCreateSheet = false

    func deleteMoment(_ moment: Moment, context: ModelContext) {
        context.delete(moment)
        try? context.save()
    }
}
