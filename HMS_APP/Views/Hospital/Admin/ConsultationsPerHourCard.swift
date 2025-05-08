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
    
    // Total completed appointments for today
    private var todayCompletedAppointments: Int {
        let calendar = Calendar.current
        let now = Date()
        
        print("DEBUG: Calculating completed consultations for today")
        
        let filtered = appointmentManager.allAppointments.filter { appointment in
            // Only count COMPLETED appointments
            guard appointment.status?.rawValue == "COMPLETED" else {
                return false
            }
            
            // Check if appointment is for today
            if let appointmentDateTime = appointment.appointmentDateTime {
                let isToday = calendar.isDate(appointmentDateTime, inSameDayAs: now)
                
                if isToday {
                    print("DEBUG: Found appointment for today - ID: \(appointment.id)")
                    return true
                }
            } else if let dateString = appointment.date {
                // Try to parse the date string
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                if let dateObj = dateFormatter.date(from: dateString),
                   calendar.isDate(dateObj, inSameDayAs: now) {
                    print("DEBUG: Found appointment with date string for today - ID: \(appointment.id)")
                    return true
                }
            }
            
            return false
        }
        
        print("DEBUG: Total completed consultations for today: \(filtered.count)")
        return filtered.count
    }
    
    // Calculate per-hour rate based on business hours
    private var currentConsults: Double {
        let workingHoursPerDay = 12.0 // Assuming 12 working hours (e.g., 8am to 8pm)
        let totalToday = Double(todayCompletedAppointments)
        
        // Calculate per-hour rate (rounded to 1 decimal place)
        let perHourRate = totalToday / workingHoursPerDay
        print("DEBUG: Per-hour rate: \(perHourRate) (based on \(totalToday) appointments over \(workingHoursPerDay) hours)")
        
        return perHourRate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Consultations Per Hour")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                    
                    Text("\(String(format: "%.1f", currentConsults))/hr")
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
        .frame(height: 85)
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
                    let date = data["date"] as? String
                    var timeString = data["time"] as? String
                    
                    if let dateTimeTimestamp = data["appointmentDateTime"] as? Timestamp {
                        appointmentDateTime = dateTimeTimestamp.dateValue()
                        print("DEBUG: Card - Appointment \(id) has timestamp: \(appointmentDateTime?.description ?? "nil")")
                    } else if let dateStr = date, let timeStr = timeString {
                        // Fallback to legacy date and time format
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd h:mm a"
                        appointmentDateTime = dateFormatter.date(from: "\(dateStr) \(timeStr)")
                        print("DEBUG: Card - Appointment \(id) parsed from date/time strings: \(appointmentDateTime?.description ?? "failed to parse")")
                    } else if let dateStr = date {
                        print("DEBUG: Card - Appointment \(id) has date (\(dateStr)) but no time")
                    }
                    
                    // Parse status with case normalization
                    var appointmentStatus: AppointmentData.AppointmentStatus? = nil
                    if let statusStr = data["status"] as? String {
                        let upperStatus = statusStr.uppercased()
                        appointmentStatus = AppointmentData.AppointmentStatus(rawValue: upperStatus)
                        print("DEBUG: Card - Appointment \(id) status: \(upperStatus)")
                    }
                    
                    // Get duration and notes
                    let durationMinutes = data["durationMinutes"] as? Int
                    let notes = data["notes"] as? String
                    let reason = data["reason"] as? String
                    
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
