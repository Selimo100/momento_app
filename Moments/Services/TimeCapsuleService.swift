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

    // MARK: Seal notifications (locked until date)

    static func scheduleUnlockNotification(for moment: Moment) {
        guard let unlockDate = moment.unlockDate, unlockDate > .now else { return }
        schedule(
            id: sealNotificationID(for: moment),
            title: "A memory is ready to reopen",
            body: "Your sealed Momento is ready.",
            at: unlockDate
        )
    }

    static func cancelUnlockNotification(for moment: Moment) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [sealNotificationID(for: moment)])
    }

    // MARK: Reminder notifications (moment stays visible)

    static func scheduleReminderNotification(for moment: Moment) {
        guard let reminderDate = moment.reminderDate, reminderDate > .now else { return }
        schedule(
            id: reminderNotificationID(for: moment),
            title: "Revisit a memory",
            body: "\"\(moment.title)\" — you set a reminder for today.",
            at: reminderDate
        )
    }

    static func cancelReminderNotification(for moment: Moment) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderNotificationID(for: moment)])
    }

    // MARK: Cancel all

    static func cancelAllNotifications(for moment: Moment) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [sealNotificationID(for: moment), reminderNotificationID(for: moment)]
        )
    }

    // MARK: Private

    private static func schedule(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private static func sealNotificationID(for moment: Moment) -> String {
        "timecapsule-seal-\(moment.id.uuidString)"
    }

    private static func reminderNotificationID(for moment: Moment) -> String {
        "timecapsule-reminder-\(moment.id.uuidString)"
    }
}
