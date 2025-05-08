//
//  HMS_APPApp.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 30/04/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import UserNotifications

@main
struct HMS_APPApp: App {
    private let notificationDelegate = NotificationDelegate()
    
    init() {
        FirebaseApp.configure()
        
        // Set notification delegate for foreground handling
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        // Request notification permissions
        NotificationManager.shared.requestPermission()
        
        // Check for appointments that need status updates
        Task {
            await AppointmentStatusService.shared.checkAndUpdateAppointmentStatuses()
        }
    }
    
    @StateObject private var authManager = AuthManager()
    @StateObject private var doctorManager = DoctorManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if authManager.isLoggedIn {
                    // Show appropriate dashboard based on user type
                    Group {
                        if let userType = UserDefaults.standard.string(forKey: "userType") {
                            switch userType {
                            case "hospital":
                                HospitalView()
                            case "doctor":
                                DoctorTabView()
                            case "patient":
                                PatientHomeView()
                            default:
                                UserSelectionView()
                            }
                        } else {
                            UserSelectionView()
                        }
                    }
                } else {
                    UserSelectionView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(doctorManager)
        }
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound for notifications when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap (e.g., navigate to appointment details)
        let userInfo = response.notification.request.content.userInfo
        if let appointmentId = userInfo["appointmentId"] as? String {
            print("ℹ️ Notification tapped for appointment: \(appointmentId)")
            // Add navigation logic here
        }
        completionHandler()
    }
}
