//
//  AppointmentStatusService.swift
//  HMS_APP
//
//  Created by rjk on 06/05/25.
//

import Foundation
import FirebaseFirestore

class AppointmentStatusService {
    static let shared = AppointmentStatusService()
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    private init() {}
    
    /// Checks for appointments that need status updates
    /// - This function should be called periodically, for example when the app starts
    /// - It will update appointments that are in 'noShow' status and haven't been confirmed by admin
    /// - Appointments older than the confirmation window will be marked as 'cancelled'
    func checkAndUpdateAppointmentStatuses() async {
        do {
            // Get current date
            let currentDate = Date()
            
            // Get all appointments with noShow status
            let snapshot = try await db.collection("\(dbName)_appointments")
                .whereField("status", isEqualTo: AppointmentData.AppointmentStatus.noShow.rawValue)
                .whereField("adminConfirmed", isEqualTo: false)
                .getDocuments()
            
            for document in snapshot.documents {
                // Check if the appointment date has passed the confirmation window
                if let appointmentDateTimestamp = document.data()["appointmentDateTime"] as? Timestamp {
                    let appointmentDate = appointmentDateTimestamp.dateValue()
                    
                    // Define the confirmation window (e.g., 24 hours before appointment)
                    let confirmationWindow = Calendar.current.date(byAdding: .hour, value: -24, to: appointmentDate) ?? appointmentDate
                    
                    // If current time is past the confirmation window and appointment hasn't been confirmed
                    if currentDate > confirmationWindow {
                        // Update the appointment status to cancelled
                        try await db.collection("\(dbName)_appointments").document(document.documentID).updateData([
                            "status": AppointmentData.AppointmentStatus.cancelled.rawValue,
                            "statusUpdateReason": "Automatically cancelled due to lack of admin confirmation"
                        ])
                        
                        print("Appointment \(document.documentID) automatically cancelled due to lack of admin confirmation")
                    }
                }
            }
        } catch {
            print("Error checking appointment statuses: \(error.localizedDescription)")
        }
    }
}
