//
//  NotificationManager.swift
//  HMS_APP
//
//  Created by s1834 on 08/05/25.
//

import UserNotifications
import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()
    private let welcomeNotificationKey = "hasReceivedWelcomeNotification"

    func requestPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.askForPermission()
                case .denied:
                    print("❌ Notification permission denied")
                    self.showSettingsAlert()
                case .authorized, .provisional, .ephemeral:
                    print("✅ Notification permission already granted")
                    self.handlePermissionGranted()
                @unknown default:
                    print("⚠️ Unknown notification authorization status")
                }
            }
        }
    }

    private func askForPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                    return
                }
                
                if granted {
                    print("✅ Notification permission granted")
                    self.handlePermissionGranted()
                } else {
                    print("❌ Notification permission denied by user")
                    self.showSettingsAlert()
                }
            }
        }
    }

    private func showSettingsAlert() {
        // In SwiftUI, open Settings directly for permission changes
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
            print("ℹ️ Redirected to Settings for notification permissions")
        } else {
            print("❌ Failed to open Settings URL")
        }
    }

    private func handlePermissionGranted() {
        let hasReceivedWelcome = UserDefaults.standard.bool(forKey: self.welcomeNotificationKey)
        if !hasReceivedWelcome {
            self.sendWelcomeNotification()
            UserDefaults.standard.set(true, forKey: self.welcomeNotificationKey)
            print("ℹ️ Welcome notification scheduled")
        } else {
            print("ℹ️ Welcome notification already sent")
        }
    }

    private func sendWelcomeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Welcome to HMS! 🩺"
        content.body = ["Your healthcare journey starts here!",
                        "Stay on top of your appointments with HMS!",
                        "We're here to help you manage your health!"].randomElement()!
        content.sound = .default
        content.userInfo = ["type": "welcome"]

        // Use a minimal delay to ensure the notification is scheduled
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: "welcomeNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to schedule welcome notification: \(error.localizedDescription)")
                } else {
                    print("✅ Welcome notification successfully scheduled")
                }
            }
        }
    }

    func scheduleAppointmentNotifications(for appointment: AppointmentData) {
        guard let appointmentDateTime = appointment.appointmentDateTime else {
            print("❌ No appointment date/time provided")
            return
        }

        // Define reminder times: 1 day before and 1 hour before
        let reminderIntervals: [TimeInterval] = [
            24 * 60 * 60, // 1 day
            60 * 60       // 1 hour
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        // Schedule notifications for both patient and doctor
        let userIds = [appointment.patientId, appointment.doctorId]

        for userId in userIds {
            for (index, interval) in reminderIntervals.enumerated() {
                let reminderDate = appointmentDateTime.addingTimeInterval(-interval)
                let timeInterval = reminderDate.timeIntervalSinceNow

                // Only schedule if the reminder time is in the future
                guard timeInterval > 0 else {
                    print("ℹ️ Skipping past reminder for \(userId) at \(dateFormatter.string(from: reminderDate))")
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = "Appointment Reminder 🩺"
                content.body = "Appointment with \(appointment.doctorName) on \(dateFormatter.string(from: appointmentDateTime))."
                content.sound = .default
                content.userInfo = [
                    "appointmentId": appointment.id,
                    "userId": userId
                ]

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                let identifier = "appointment_\(appointment.id)_\(userId)_\(index)"

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ Failed to schedule appointment notification \(identifier): \(error.localizedDescription)")
                        } else {
                            print("✅ Scheduled notification \(identifier) for \(dateFormatter.string(from: reminderDate))")
                        }
                    }
                }
            }
        }
    }

    func cancelAppointmentNotifications(for appointmentId: String, userId: String) {
        let identifiers = [
            "appointment_\(appointmentId)_\(userId)_0",
            "appointment_\(appointmentId)_\(userId)_1"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("ℹ️ Cancelled notifications for appointment \(appointmentId) and user \(userId)")
    }
}
