import Foundation
import UserNotifications

struct TimeCapsuleService {

    static func requestNotificationPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func scheduleUnlockNotification(for moment: Moment) {
        guard let unlockDate = moment.unlockDate, unlockDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "A memory is ready to reopen"
        content.body = "Your Momento time capsule is ready."
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: unlockDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationID(for: moment),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelNotification(for moment: Moment) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID(for: moment)])
    }

    private static func notificationID(for moment: Moment) -> String {
        "timecapsule-\(moment.id.uuidString)"
    }
}
