import Foundation

struct CompletionCriterion {
    let label: String
    let systemImage: String
    let isComplete: Bool
    let weight: Int
}

extension Moment {
    var completionCriteria: [CompletionCriterion] {
        [
            CompletionCriterion(
                label: "Title",
                systemImage: "textformat",
                isComplete: !title.trimmingCharacters(in: .whitespaces).isEmpty,
                weight: 15
            ),
            CompletionCriterion(
                label: "Description",
                systemImage: "text.alignleft",
                isComplete: !momentDescription.trimmingCharacters(in: .whitespaces).isEmpty,
                weight: 15
            ),
            CompletionCriterion(
                label: "Story",
                systemImage: "book.pages",
                isComplete: !(story ?? "").trimmingCharacters(in: .whitespaces).isEmpty,
                weight: 15
            ),
            CompletionCriterion(
                label: "Cover Photo",
                systemImage: "photo",
                isComplete: coverPhotoId != nil,
                weight: 15
            ),
            CompletionCriterion(
                label: "5 Photos",
                systemImage: "photo.stack",
                isComplete: photos.count >= 5,
                weight: 20
            ),
            CompletionCriterion(
                label: "Best Shot",
                systemImage: "heart",
                isComplete: photos.contains(where: \.isFavorite),
                weight: 10
            ),
            CompletionCriterion(
                label: "Exported",
                systemImage: "square.and.arrow.up",
                isComplete: hasBeenExported,
                weight: 10
            ),
        ]
    }

    var completionPercentage: Int {
        completionCriteria.filter(\.isComplete).reduce(0) { $0 + $1.weight }
    }

    var completionHint: String {
        guard completionPercentage < 100 else { return "This moment is complete." }
        guard let first = completionCriteria.first(where: { !$0.isComplete }) else { return "" }
        switch first.label {
        case "Story":       return "Add a story to make this moment more personal."
        case "Cover Photo": return "Choose a cover photo."
        case "Best Shot":   return "Mark your best shot as a favorite."
        case "5 Photos":    return "Add at least 5 photos for a richer moment."
        case "Description": return "Add a short description."
        case "Exported":    return "Export this moment to Apple Photos."
        default:            return "Keep going — you're almost there."
        }
    }
}
