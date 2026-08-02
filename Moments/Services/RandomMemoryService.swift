import Foundation

/// The different ways a user can be surprised with a memory.
enum SurpriseMode: String, CaseIterable, Identifiable {
    case randomMoment
    case bestShot
    case thisMonth
    case aroundThisDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .randomMoment: return "Random Moment"
        case .bestShot: return "Random Best Shot"
        case .thisMonth: return "This Month"
        case .aroundThisDate: return "Around This Date"
        }
    }

    var icon: String {
        switch self {
        case .randomMoment: return "shuffle"
        case .bestShot: return "heart.fill"
        case .thisMonth: return "calendar"
        case .aroundThisDate: return "clock.arrow.circlepath"
        }
    }
}

/// What the surprise resolved to: a moment to open, and optionally a photo to highlight.
struct SurpriseResult {
    let moment: Moment
    let photo: MomentPhoto?
}

/// Friendly, user-facing reasons a surprise couldn't be produced.
enum SurpriseError: Error {
    case noMoments
    case noBestShots
    case noneThisMonth
    case noneAroundDate

    var message: String {
        switch self {
        case .noMoments:
            return "No memories to surprise you with yet. Add a moment first."
        case .noBestShots:
            return "No best shots yet. Mark your favorite photos first."
        case .noneThisMonth:
            return "No memories from this month yet. Keep collecting moments!"
        case .noneAroundDate:
            return "Nothing from around this date in another year — yet."
        }
    }
}

/// Pure, testable logic for picking a random memory.
///
/// All entry points exclude future-locked Time Capsules. Ready-to-reopen
/// capsules are treated as normal, openable moments.
enum RandomMemoryService {

    /// Moments the user is allowed to open right now.
    ///
    /// Excludes locked future capsules and — unless explicitly opted in from
    /// the authenticated private area — private moments.
    static func openableMoments(from moments: [Moment], includePrivate: Bool = false) -> [Moment] {
        moments.filter { !$0.isLocked && (includePrivate || !$0.isPrivate) }
    }

    /// The representative date used for date-based filtering.
    static func referenceDate(for moment: Moment) -> Date {
        moment.startDate ?? moment.createdAt
    }

    /// Resolve a surprise for the given mode.
    static func pick(
        mode: SurpriseMode,
        from moments: [Moment],
        includePrivate: Bool = false,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Result<SurpriseResult, SurpriseError> {
        let openable = openableMoments(from: moments, includePrivate: includePrivate)

        switch mode {
        case .randomMoment:
            guard let moment = openable.randomElement() else {
                return .failure(.noMoments)
            }
            return .success(SurpriseResult(moment: moment, photo: nil))

        case .bestShot:
            let pairs: [(Moment, MomentPhoto)] = openable.flatMap { moment in
                moment.photos.filter(\.isFavorite).map { (moment, $0) }
            }
            guard let chosen = pairs.randomElement() else {
                return .failure(.noBestShots)
            }
            return .success(SurpriseResult(moment: chosen.0, photo: chosen.1))

        case .thisMonth:
            let currentMonth = calendar.component(.month, from: now)
            let candidates = openable.filter {
                calendar.component(.month, from: referenceDate(for: $0)) == currentMonth
            }
            guard let moment = candidates.randomElement() else {
                return .failure(.noneThisMonth)
            }
            return .success(SurpriseResult(moment: moment, photo: nil))

        case .aroundThisDate:
            let dayWindow = 7
            let candidates = openable.filter {
                isWithinDayWindow(referenceDate(for: $0), of: now, days: dayWindow, calendar: calendar)
            }
            guard let moment = candidates.randomElement() else {
                return .failure(.noneAroundDate)
            }
            return .success(SurpriseResult(moment: moment, photo: nil))
        }
    }

    /// True when `date` falls within ±`days` of `reference`'s month/day, ignoring the year.
    static func isWithinDayWindow(
        _ date: Date,
        of reference: Date,
        days: Int,
        calendar: Calendar
    ) -> Bool {
        guard
            let refDay = calendar.ordinality(of: .day, in: .year, for: reference),
            let day = calendar.ordinality(of: .day, in: .year, for: date)
        else { return false }

        let yearLength = calendar.range(of: .day, in: .year, for: date)?.count ?? 365
        let rawDiff = abs(day - refDay)
        // Handle year wrap-around (e.g. Dec 30 vs Jan 2).
        let diff = min(rawDiff, yearLength - rawDiff)
        return diff <= days
    }
}
