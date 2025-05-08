//
//  AppointmentManager.swift
//  MediCareManager
//
//  Created by s1834 on 18/04/25.
//

import Foundation
import FirebaseFirestore

class AppointmentManager: ObservableObject {
    @Published var allAppointments: [AppointmentData] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    var patientAppointments: [AppointmentData] = []
    
    init() {
        // Initial fetch when class is initialized
        Task { @MainActor in
            await fetchAppointments()
        }
    }
    
    @MainActor
    func fetchAppointments() async {
        isLoading = true
        
        guard let patientId = UserDefaults.standard.string(forKey: "userId"), !patientId.isEmpty else {
            isLoading = false
            error = "User not logged in"
            print("DEBUG: No userId found in UserDefaults")
            return
        }
        
        await fetchAppointments(for: patientId)
    }
    
    @MainActor
    func fetchAppointments(for patientId: String) async {
        isLoading = true
        
        print("DEBUG: Fetching appointments for patient ID: \(patientId)")
        
        do {
            // Query appointments for this patient
            let snapshot = try await db.collection("\(dbName)_appointments")
                .whereField("patId", isEqualTo: patientId)
                .getDocuments()
            
            print("DEBUG: Firestore returned \(snapshot.documents.count) appointments")
            
            // Process the results
            var appointments: [AppointmentData] = []
            
            for document in snapshot.documents {
                let data = document.data()
                print("DEBUG: Processing appointment document: \(document.documentID)")
                
                guard let id = data["id"] as? String,
                      let doctorId = data["docId"] as? String,
                      let doctorName = data["docName"] as? String else {
                    print("DEBUG: Missing required fields in appointment document")
                    continue
                }
                
                // Get patient name
                let patientName = data["patName"] as? String ?? ""
                
                // Get patient records ID
                let patientRecordsId = data["patientRecordsId"] as? String ?? patientId
                
                // Parse appointment date time
                var appointmentDateTime: Date? = nil
                if let dateTimeTimestamp = data["appointmentDateTime"] as? Timestamp {
                    appointmentDateTime = dateTimeTimestamp.dateValue()
                } else if let dateStr = data["date"] as? String, let timeStr = data["time"] as? String {
                    // Fallback to legacy date and time format
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm a"
                    appointmentDateTime = dateFormatter.date(from: "\(dateStr) \(timeStr)")
                }
                
                // Parse status
                var appointmentStatus: AppointmentData.AppointmentStatus? = nil
                if let statusStr = data["status"] as? String {
                    switch statusStr.uppercased() {
                    case "SCHEDULED":
                        appointmentStatus = .scheduled
                    case "IN_PROGRESS":
                        appointmentStatus = .inProgress
                    case "COMPLETED":
                        appointmentStatus = .completed
                    case "CANCELLED":
                        appointmentStatus = .cancelled
                    case "WAITING":
                        appointmentStatus = .noShow
                    case "RESCHEDULED":
                        appointmentStatus = .rescheduled
                    default:
                        appointmentStatus = .scheduled
                    }
                }
                
                // Get duration and notes
                let durationMinutes = data["durationMinutes"] as? Int
                let notes = data["notes"] as? String ?? data["reason"] as? String
                
                let appointment = AppointmentData(
                    id: id,
                    patientId: patientId,
                    patientName: patientName,
                    doctorId: doctorId,
                    doctorName: doctorName,
                    patientRecordsId: patientRecordsId,
                    appointmentDateTime: appointmentDateTime,
                    status: appointmentStatus,
                    durationMinutes: durationMinutes,
                    notes: notes
                )
                
                print("DEBUG: Added appointment - ID: \(id), Doctor: \(doctorName)")
                appointments.append(appointment)
            }
            
            // Sort appointments by date and time
            appointments.sort { (app1, app2) -> Bool in
                guard let date1 = app1.appointmentDateTime, let date2 = app2.appointmentDateTime else {
                    return false
                }
                return date1 > date2
            }
            
            self.patientAppointments = appointments
            print("DEBUG: Total appointments after sorting: \(appointments.count)")
            
            self.isLoading = false
            self.error = nil
            
        } catch {
            self.isLoading = false
            self.error = "Error fetching appointments: \(error.localizedDescription)"
            print("DEBUG: Error fetching appointments: \(error.localizedDescription)")
        }
    }
    
    func cancelAppointment(appointmentId: String) {
        Task {
            do {
                try await db.collection("\(dbName)_appointments").document(appointmentId).updateData([
                    "status": AppointmentData.AppointmentStatus.cancelled.rawValue
                ])
                
                // Refresh the appointments list
                await fetchAppointments()
            } catch {
                await MainActor.run {
                    self.error = "Error cancelling appointment: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func rescheduleAppointment(appointmentId: String, newDate: Date) async throws {
        // Format the date for Firestore query
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: newDate)
        
        // Format the time for Firestore query
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        let timeString = timeFormatter.string(from: newDate)
        
        // Check if the new time slot is available
        let snapshot = try await db.collection("\(dbName)_appointments")
            .whereField("date", isEqualTo: dateString)
            .whereField("time", isEqualTo: timeString)
            .getDocuments()
            
        // If there's already an appointment at this time (and it's not the one we're rescheduling)
        for doc in snapshot.documents {
            if let id = doc.data()["id"] as? String, id != appointmentId {
                throw NSError(domain: "AppointmentError", 
                             code: 1, 
                             userInfo: [NSLocalizedDescriptionKey: "This time slot is already booked"])
            }
        }
        
        // Update the appointment with new date and time
        try await db.collection("\(dbName)_appointments").document(appointmentId).updateData([
            "appointmentDateTime": newDate,
            "status": AppointmentData.AppointmentStatus.rescheduled.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        // Also update legacy fields for backward compatibility
        try await db.collection("\(dbName)_appointments").document(appointmentId).updateData([
            "date": dateString,
            "time": timeString
        ])
        
        // Refresh the appointments list
        await fetchAppointments()
    }
}
