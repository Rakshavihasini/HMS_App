//
//  ConsultationsPerHourCard.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import FirebaseFirestore

struct ConsultationsPerHourCard: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var appointmentManager = AppointmentManager()
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    private var currentConsults: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        return appointmentManager.allAppointments.filter { appointment in
            // Only count COMPLETED appointments
            guard appointment.status?.rawValue == "COMPLETED" else {
                return false
            }
            
            // First try to use appointmentDateTime if available
            if let appointmentDateTime = appointment.appointmentDateTime {
                let appointmentHour = calendar.component(.hour, from: appointmentDateTime)
                let isToday = calendar.isDate(appointmentDateTime, inSameDayAs: now)
                return isToday && appointmentHour == currentHour
            }
            
            // Try to use date string if appointmentDateTime is not available
            if let dateStr = appointment.date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let dateObj = formatter.date(from: dateStr) {
                    let isToday = calendar.isDate(dateObj, inSameDayAs: now)
                    // Since we don't have a specific hour, we'll consider it as current hour
                    return isToday
                }
            }
            
            return false
        }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Completed Consultations")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                    
                    Text("\(currentConsults)/hr")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(currentTheme.primary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(currentTheme.primary)
                }
            }
            
        }
        .padding()
        .background(currentTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTheme.border, lineWidth: 1)
        )
        .shadow(color: currentTheme.shadow, radius: 10, x: 0, y: 2)
        .onAppear {
            fetchCompletedAppointments()
        }
    }
    
    private func fetchCompletedAppointments() {
        Task {
            do {
                let firestore = Firestore.firestore()
                let appointmentsCollection = "hms4_appointments"
                
                // First try with uppercase
                let snapshotUpper = try await firestore.collection(appointmentsCollection)
                    .whereField("status", isEqualTo: "COMPLETED")
                    .getDocuments()
                
                // Then try with lowercase (might exist in the database)
                let snapshotLower = try await firestore.collection(appointmentsCollection)
                    .whereField("status", isEqualTo: "completed")
                    .getDocuments()
                    
                // Combine the documents (avoiding duplicates by id)
                var uniqueDocuments = [String: QueryDocumentSnapshot]()
                
                for doc in snapshotUpper.documents {
                    uniqueDocuments[doc.documentID] = doc
                }
                
                for doc in snapshotLower.documents {
                    uniqueDocuments[doc.documentID] = doc
                }
                
                print("DEBUG: Card - Found \(snapshotUpper.documents.count) uppercase COMPLETED appointments")
                print("DEBUG: Card - Found \(snapshotLower.documents.count) lowercase completed appointments")
                print("DEBUG: Card - Total unique completed appointments: \(uniqueDocuments.count)")
                
                var appointments: [AppointmentData] = []
                
                for (_, document) in uniqueDocuments {
                    let data = document.data()
                    
                    // Get basic appointment data
                    let id = document.documentID
                    let patientId = data["patId"] as? String ?? ""
                    let patientName = data["patName"] as? String ?? ""
                    let doctorId = data["docId"] as? String ?? ""
                    let doctorName = data["docName"] as? String ?? ""
                    let patientRecordsId = data["patientRecordsId"] as? String ?? ""
                    
                    // Parse appointment date time
                    var appointmentDateTime: Date? = nil
                    if let dateTimeTimestamp = data["appointmentDateTime"] as? Timestamp {
                        appointmentDateTime = dateTimeTimestamp.dateValue()
                    } else if let dateStr = data["date"] as? String, let timeStr = data["time"] as? String {
                        // Fallback to legacy date and time format
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"
                        appointmentDateTime = dateFormatter.date(from: "\(dateStr) \(timeStr)")
                    }
                    
                    // Parse status with case normalization
                    var appointmentStatus: AppointmentData.AppointmentStatus? = nil
                    if let statusStr = data["status"] as? String {
                        let upperStatus = statusStr.uppercased()
                        appointmentStatus = AppointmentData.AppointmentStatus(rawValue: upperStatus)
                    }
                    
                    // Get duration and notes
                    let durationMinutes = data["durationMinutes"] as? Int
                    let notes = data["notes"] as? String
                    let reason = data["reason"] as? String
                    let date = data["date"] as? String
                    
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
                        notes: notes,
                        date: date,
                        reason: reason
                    )
                    
                    appointments.append(appointment)
                }
                
                print("DEBUG: Card - Total appointments after processing: \(appointments.count)")
                
                await MainActor.run {
                    self.appointmentManager.allAppointments = appointments
                }
            } catch {
                print("DEBUG: Card - Error fetching completed consultations: \(error)")
            }
        }
    }
}
