//
//  HMS_APPApp.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 30/04/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct HMS_APPApp: App {
    init() {
        FirebaseApp.configure()
        
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
//            NMCLicenseVerificationView()
        }
    }
}
