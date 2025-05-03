//
//  AppointmentModel.swift
//  Hms
//
//  Created by admin49 on 30/04/25.
//

import Foundation
import FirebaseFirestore


/// A model representing a medical appointment in the healthcare system
struct AppointmentData: Identifiable, Codable {
    /// The unique identifier for the appointment
    let id: String
    
    /// The unique identifier of the patient
    let patientId: String
    
    /// The name of the patient
    let patientName: String
    
    /// The unique identifier of the doctor
    let doctorId: String
    
    /// The name of the doctor
    let doctorName: String
    
    /// The patient's Appwrite ID (for linking to patient records)
    let patientRecordsId: String
    
    /// The date and time of the appointment
    let appointmentDateTime: Date?
    
    /// The status of the appointment (e.g., scheduled, completed, cancelled)
    let status: AppointmentStatus?
    
    /// The duration of the appointment in minutes
    let durationMinutes: Int?
    
    /// Any notes for the appointment
    let notes: String?
    
    let date: String?
    
    let reason: String?
    
    var time: String {
        if let dateTime = appointmentDateTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: dateTime)
        }
        return ""
    }
    
    var dateObject: Date? {
        if let dateStr = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateStr)
        }
        return appointmentDateTime
    }
    
    /// Enum representing possible appointment statuses
    enum AppointmentStatus: String, Codable {
        case scheduled = "SCHEDULED"
        case inProgress = "IN_PROGRESS"
        case completed = "COMPLETED"
        case cancelled = "CANCELLED"
        case noShow = "NO_SHOW"
        case rescheduled = "RESCHEDULED"
    }
    
    /// Creates a new Appointment instance
    /// - Parameters:
    ///   - id: The unique identifier for the appointment
    ///   - patientId: The unique identifier of the patient
    ///   - patientName: The name of the patient
    ///   - doctorId: The unique identifier of the doctor
    ///   - doctorName: The name of the doctor
    ///   - patientRecordsId: The patient's Appwrite ID (for linking to patient records)
    ///   - appointmentDateTime: The date and time of the appointment (optional)
    ///   - status: The status of the appointment (optional)
    ///   - durationMinutes: The duration of the appointment in minutes (optional)
    ///   - notes: Any notes for the appointment (optional)
    init(
        id: String,
        patientId: String,
        patientName: String,
        doctorId: String,
        doctorName: String,
        patientRecordsId: String,
        appointmentDateTime: Date? = nil,
        status: AppointmentStatus? = nil,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        date: String? = nil,
        reason: String? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.patientName = patientName
        self.doctorId = doctorId
        self.doctorName = doctorName
        self.patientRecordsId = patientRecordsId
        self.appointmentDateTime = appointmentDateTime
        self.status = status
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.date = date
        self.reason = reason
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patId"
        case patientName = "patName"
        case doctorId = "docId"
        case doctorName = "docName"
        case patientRecordsId = "patientRecordsId"
        case appointmentDateTime
        case status
        case durationMinutes
        case notes
        case date
        case reason
    }
    
    // MARK: - Additional functionality
    
    /// Returns a formatted string with the appointment's basic information
    var basicInfo: String {
        var info = "Patient: \(patientName) | Doctor: \(doctorName)"
        
        if let dateTime = appointmentDateTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            info += " | \(dateFormatter.string(from: dateTime))"
        }
        
        if let status = status {
            info += " | \(status.rawValue)"
        }
        
        return info
    }
    
    /// Checks if the appointment is upcoming
    var isUpcoming: Bool {
        guard let dateTime = appointmentDateTime else { return false }
        return dateTime > Date() && (status == .scheduled || status == .rescheduled)
    }
    
    /// Returns the end time of the appointment (if duration and start time are available)
    var endTime: Date? {
        guard let startTime = appointmentDateTime, let duration = durationMinutes else { return nil }
        return Calendar.current.date(byAdding: .minute, value: duration, to: startTime)
    }
    
    /// Returns a time range string for the appointment
    var timeRangeString: String? {
        guard let startTime = appointmentDateTime else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var result = dateFormatter.string(from: startTime)
        
        if let endTime = endTime {
            // Use a second formatter for just the time of the end time
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            result += " - \(timeFormatter.string(from: endTime))"
        }
        
        return result
    }
}

// MARK: - Extensions for AppointmentData

extension AppointmentData {
    /// Creates a sample appointment for preview and testing purposes
    static var sample: AppointmentData {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let appointmentTime = dateFormatter.date(from: "2025-05-15 14:30")
        
        return AppointmentData(
            id: "apt456",
            patientId: "pat123",
            patientName: "Jane Doe",
            doctorId: "doc789",
            doctorName: "Dr. John Smith",
            patientRecordsId: "pat123_records",
            appointmentDateTime: appointmentTime,
            status: .scheduled,
            durationMinutes: 30,
            notes: "Follow-up appointment for medication review",
            date: dateFormatter.string(from: appointmentTime!),
            reason: "Checkup"
        )
    }
}

// MARK: - Appointment ViewModel

// Appointment class that conforms to ObservableObject to be used as a StateObject
class Appointment: ObservableObject {
    @Published var upcomingAppointments: [AppointmentData] = []
    @Published var pastAppointments: [AppointmentData] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    init() {}
    
    init(from: AppointmentData) {
        // This initializer is for creating an Appointment object from AppointmentData
        // Will be implemented as needed
    }
    
    @MainActor
    func fetchAppointments(for doctorId: String) async {
        isLoading = true
        error = nil
        
        do {
            let query = db.collection("\(dbName)_appointments").whereField("docId", isEqualTo: doctorId)
            let snapshot = try await query.getDocuments()
            
            var upcoming: [AppointmentData] = []
            var past: [AppointmentData] = []
            
            for document in snapshot.documents {
                if let appointment = parseAppointment(document: document) {
                    if appointment.isUpcoming {
                        upcoming.append(appointment)
                    } else {
                        past.append(appointment)
                    }
                }
            }
            
            // Sort upcoming appointments by date (earliest first)
            upcoming.sort { (a, b) -> Bool in
                guard let dateA = a.appointmentDateTime, let dateB = b.appointmentDateTime else {
                    return false
                }
                return dateA < dateB
            }
            
            // Sort past appointments by date (most recent first)
            past.sort { (a, b) -> Bool in
                guard let dateA = a.appointmentDateTime, let dateB = b.appointmentDateTime else {
                    return false
                }
                return dateA > dateB
            }
            
            self.upcomingAppointments = upcoming
            self.pastAppointments = past
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.error = "Error fetching appointments: \(error.localizedDescription)"
        }
    }
    
    private func parseAppointment(document: QueryDocumentSnapshot) -> AppointmentData? {
        let data = document.data()
        
        // Parse date and time
        var appointmentDateTime: Date? = nil
        if let timestamp = data["appointmentDateTime"] as? Timestamp {
            appointmentDateTime = timestamp.dateValue()
        }
        
        // Parse status
        var status: AppointmentData.AppointmentStatus? = nil
        if let statusString = data["status"] as? String,
           let appointmentStatus = AppointmentData.AppointmentStatus(rawValue: statusString) {
            status = appointmentStatus
        }
        
        return AppointmentData(
            id: document.documentID,
            patientId: data["patId"] as? String ?? "",
            patientName: data["patName"] as? String ?? "",
            doctorId: data["docId"] as? String ?? "",
            doctorName: data["docName"] as? String ?? "",
            patientRecordsId: data["patientRecordsId"] as? String ?? "",
            appointmentDateTime: appointmentDateTime,
            status: status,
            durationMinutes: data["durationMinutes"] as? Int,
            notes: data["notes"] as? String,
            date: data["date"] as? String,
            reason: data["reason"] as? String
        )
    }
    
    // Function to update appointment status
    @MainActor
    func updateAppointmentStatus(appointmentId: String, newStatus: AppointmentData.AppointmentStatus) async -> Bool {
        do {
            try await db.collection("\(dbName)_appointments").document(appointmentId).updateData([
                "status": newStatus.rawValue
            ])
            
            // Update local data
            if let index = upcomingAppointments.firstIndex(where: { $0.id == appointmentId }) {
                // Create a copy of the appointment with updated status
                let oldAppointment = upcomingAppointments[index]
                let updatedAppointment = AppointmentData(
                    id: oldAppointment.id,
                    patientId: oldAppointment.patientId,
                    patientName: oldAppointment.patientName,
                    doctorId: oldAppointment.doctorId,
                    doctorName: oldAppointment.doctorName,
                    patientRecordsId: oldAppointment.patientRecordsId,
                    appointmentDateTime: oldAppointment.appointmentDateTime,
                    status: newStatus,
                    durationMinutes: oldAppointment.durationMinutes,
                    notes: oldAppointment.notes,
                    date: oldAppointment.date,
                    reason: oldAppointment.reason
                )
                
                // Depending on the new status, move the appointment between lists
                if newStatus == .completed || newStatus == .cancelled || newStatus == .noShow {
                    upcomingAppointments.remove(at: index)
                    pastAppointments.insert(updatedAppointment, at: 0)
                } else {
                    upcomingAppointments[index] = updatedAppointment
                }
            } else if let index = pastAppointments.firstIndex(where: { $0.id == appointmentId }) {
                // Similar logic for past appointments
                let oldAppointment = pastAppointments[index]
                let updatedAppointment = AppointmentData(
                    id: oldAppointment.id,
                    patientId: oldAppointment.patientId,
                    patientName: oldAppointment.patientName,
                    doctorId: oldAppointment.doctorId,
                    doctorName: oldAppointment.doctorName,
                    patientRecordsId: oldAppointment.patientRecordsId,
                    appointmentDateTime: oldAppointment.appointmentDateTime,
                    status: newStatus,
                    durationMinutes: oldAppointment.durationMinutes,
                    notes: oldAppointment.notes,
                    date: oldAppointment.date,
                    reason: oldAppointment.reason
                )
                
                // If status changes to scheduled or rescheduled, move to upcoming
                if newStatus == .scheduled || newStatus == .rescheduled {
                    pastAppointments.remove(at: index)
                    upcomingAppointments.append(updatedAppointment)
                    // Sort upcoming appointments
                    upcomingAppointments.sort { (a, b) -> Bool in
                        guard let dateA = a.appointmentDateTime, let dateB = b.appointmentDateTime else {
                            return false
                        }
                        return dateA < dateB
                    }
                } else {
                    pastAppointments[index] = updatedAppointment
                }
            }
            
            return true
        } catch {
            self.error = "Error updating appointment status: \(error.localizedDescription)"
            return false
        }
    }
    
    // Function to reschedule an appointment
    @MainActor
    func rescheduleAppointment(appointmentId: String, newDate: Date) async -> Bool {
        do {
            // Format the date string
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: newDate)
            
            // Format the time string
            dateFormatter.dateFormat = "h:mm a"
            let timeString = dateFormatter.string(from: newDate)
            
            try await db.collection("\(dbName)_appointments").document(appointmentId).updateData([
                "appointmentDateTime": newDate,
                "date": dateString,
                "time": timeString,
                "status": AppointmentData.AppointmentStatus.rescheduled.rawValue
            ])
            
            // Update local data
            let updateLocalAppointment = { (oldAppointment: AppointmentData) -> AppointmentData in
                return AppointmentData(
                    id: oldAppointment.id,
                    patientId: oldAppointment.patientId,
                    patientName: oldAppointment.patientName,
                    doctorId: oldAppointment.doctorId,
                    doctorName: oldAppointment.doctorName,
                    patientRecordsId: oldAppointment.patientRecordsId,
                    appointmentDateTime: newDate,
                    status: .rescheduled,
                    durationMinutes: oldAppointment.durationMinutes,
                    notes: oldAppointment.notes,
                    date: dateString,
                    reason: oldAppointment.reason
                )
            }
            
            if let index = upcomingAppointments.firstIndex(where: { $0.id == appointmentId }) {
                let oldAppointment = upcomingAppointments[index]
                let updatedAppointment = updateLocalAppointment(oldAppointment)
                upcomingAppointments[index] = updatedAppointment
                
                // Re-sort the upcoming appointments
                upcomingAppointments.sort { (a, b) -> Bool in
                    guard let dateA = a.appointmentDateTime, let dateB = b.appointmentDateTime else {
                        return false
                    }
                    return dateA < dateB
                }
            } else if let index = pastAppointments.firstIndex(where: { $0.id == appointmentId }) {
                let oldAppointment = pastAppointments[index]
                let updatedAppointment = updateLocalAppointment(oldAppointment)
                
                // Remove from past and add to upcoming
                pastAppointments.remove(at: index)
                upcomingAppointments.append(updatedAppointment)
                
                // Re-sort the upcoming appointments
                upcomingAppointments.sort { (a, b) -> Bool in
                    guard let dateA = a.appointmentDateTime, let dateB = b.appointmentDateTime else {
                        return false
                    }
                    return dateA < dateB
                }
            }
            
            return true
        } catch {
            self.error = "Error rescheduling appointment: \(error.localizedDescription)"
            return false
        }
    }
    
    // Static function to provide sample appointments for preview and testing
    static func sampleAppointments() -> [AppointmentData] {
        return [AppointmentData.sample]
    }
}
