import Foundation

extension DateFormatter {
    static let momentDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    static let momentShort: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static func momentRange(from start: Date, to end: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: start, to: end)
    }

    static func momentShortRange(from start: Date, to end: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: start, to: end)
    }
}
