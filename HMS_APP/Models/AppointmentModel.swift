////
////  AppointmentModel.swift
////  Hms
////
////  Created by admin49 on 30/04/25.
////
//
//import Foundation
//
///// A model representing a medical appointment in the healthcare system
//struct Appointment: Identifiable, Codable {
//    /// The unique identifier for the appointment
//    let id: String
//    
//    /// The unique identifier of the patient
//    let patientId: String
//    
//    /// The name of the patient
//    let patientName: String
//    
//    /// The unique identifier of the doctor
//    let doctorId: String
//    
//    /// The name of the doctor
//    let doctorName: String
//    
//    /// The patient's Appwrite ID (for linking to patient records)
//    let patientRecordsId: String
//    
//    /// The date and time of the appointment
//    let appointmentDateTime: Date?
//    
//    /// The status of the appointment (e.g., scheduled, completed, cancelled)
//    let status: AppointmentStatus?
//    
//    /// The duration of the appointment in minutes
//    let durationMinutes: Int?
//    
//    /// Any notes for the appointment
//    let notes: String?
//    
//    /// Enum representing possible appointment statuses
//    enum AppointmentStatus: String, Codable {
//        case scheduled = "SCHEDULED"
//        case inProgress = "IN_PROGRESS"
//        case completed = "COMPLETED"
//        case cancelled = "CANCELLED"
//        case noShow = "NO_SHOW"
//        case rescheduled = "RESCHEDULED"
//    }
//    
//    /// Creates a new Appointment instance
//    /// - Parameters:
//    ///   - id: The unique identifier for the appointment
//    ///   - patientId: The unique identifier of the patient
//    ///   - patientName: The name of the patient
//    ///   - doctorId: The unique identifier of the doctor
//    ///   - doctorName: The name of the doctor
//    ///   - patientRecordsId: The patient's Appwrite ID (for linking to patient records)
//    ///   - appointmentDateTime: The date and time of the appointment (optional)
//    ///   - status: The status of the appointment (optional)
//    ///   - durationMinutes: The duration of the appointment in minutes (optional)
//    ///   - notes: Any notes for the appointment (optional)
//    init(
//        id: String,
//        patientId: String,
//        patientName: String,
//        doctorId: String,
//        doctorName: String,
//        patientRecordsId: String,
//        appointmentDateTime: Date? = nil,
//        status: AppointmentStatus? = nil,
//        durationMinutes: Int? = nil,
//        notes: String? = nil
//    ) {
//        self.id = id
//        self.patientId = patientId
//        self.patientName = patientName
//        self.doctorId = doctorId
//        self.doctorName = doctorName
//        self.patientRecordsId = patientRecordsId
//        self.appointmentDateTime = appointmentDateTime
//        self.status = status
//        self.durationMinutes = durationMinutes
//        self.notes = notes
//    }
//    
//    // MARK: - Codable
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case patientId = "patId"
//        case patientName = "patName"
//        case doctorId = "docId"
//        case doctorName = "docName"
//        case patientRecordsId = "patientRecordsId"
//        case appointmentDateTime
//        case status
//        case durationMinutes
//        case notes
//    }
//    
//    // MARK: - Additional functionality
//    
//    /// Returns a formatted string with the appointment's basic information
//    var basicInfo: String {
//        var info = "Patient: \(patientName) | Doctor: \(doctorName)"
//        
//        if let dateTime = appointmentDateTime {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateStyle = .medium
//            dateFormatter.timeStyle = .short
//            info += " | \(dateFormatter.string(from: dateTime))"
//        }
//        
//        if let status = status {
//            info += " | \(status.rawValue)"
//        }
//        
//        return info
//    }
//    
//    /// Checks if the appointment is upcoming
//    var isUpcoming: Bool {
//        guard let dateTime = appointmentDateTime else { return false }
//        return dateTime > Date() && (status == .scheduled || status == .rescheduled)
//    }
//    
//    /// Returns the end time of the appointment (if duration and start time are available)
//    var endTime: Date? {
//        guard let startTime = appointmentDateTime, let duration = durationMinutes else { return nil }
//        return Calendar.current.date(byAdding: .minute, value: duration, to: startTime)
//    }
//    
//    /// Returns a time range string for the appointment
//    var timeRangeString: String? {
//        guard let startTime = appointmentDateTime else { return nil }
//        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .medium
//        dateFormatter.timeStyle = .short
//        
//        var result = dateFormatter.string(from: startTime)
//        
//        if let endTime = endTime {
//            // Use a second formatter for just the time of the end time
//            let timeFormatter = DateFormatter()
//            timeFormatter.dateStyle = .none
//            timeFormatter.timeStyle = .short
//            result += " - \(timeFormatter.string(from: endTime))"
//        }
//        
//        return result
//    }
//}
//
//// MARK: - Extensions for Appointment
//
//extension Appointment {
//    /// Creates a sample appointment for preview and testing purposes
//    static var sample: Appointment {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
//        let appointmentTime = dateFormatter.date(from: "2025-05-15 14:30")
//        
//        return Appointment(
//            id: "apt456",
//            patientId: "pat123",
//            patientName: "Jane Doe",
//            doctorId: "doc789",
//            doctorName: "Dr. John Smith",
//            patientRecordsId: "pat123_records",
//            appointmentDateTime: appointmentTime,
//            status: .scheduled,
//            durationMinutes: 30,
//            notes: "Follow-up appointment for medication review"
//        )
//    }
//}
