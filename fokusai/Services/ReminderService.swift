//
//  ReminderService.swift
//  fokusai
//
//  Daily encouraging reminder — never guilt-based, never "you're about to
//  lose your streak!".
//

import Foundation
import UserNotifications

enum ReminderService {
    private static let reminderID = "fokusai.dailyReminder"

    static func scheduleDaily(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Your orb says hi"
            content.body = "One 2-minute step keeps the flame alive 🔥"
            content.sound = .default

            var components = Calendar.current.dateComponents([.hour, .minute], from: time)
            components.second = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)

            center.removePendingNotificationRequests(withIdentifiers: [reminderID])
            center.add(request)
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}
