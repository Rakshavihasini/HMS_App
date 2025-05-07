//
//  ConsultationsChartView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//


import SwiftUI
import Charts
import FirebaseFirestore

struct ConsultationsChartView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var appointmentManager = AppointmentManager()
    @State private var consultationsData: [ConsultationData] = []
    @State private var totalConsultations: Int = 0
    @State private var peakConsultations: Int = 0
    @State private var averageDuration: Int = 0
    @State private var selectedDate: Date = Date()
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Consultations")
                        .font(.headline)
                        .foregroundColor(currentTheme.text)
                    
                    HStack {
                        Button(action: {
                            withAnimation {
                                selectedDate = Date()
                                processAppointmentData()
                            }
                        }) {
                            Text(Calendar.current.isDateInToday(selectedDate) ? "Today" : dateString)
                                .font(.subheadline)
                                .foregroundColor(currentTheme.text.opacity(0.6))
                        }
                        
                        if !Calendar.current.isDateInToday(selectedDate) {
                            Text("•")
                                .foregroundColor(currentTheme.text.opacity(0.6))
                            Button(action: {
                                withAnimation {
                                    selectedDate = Date()
                                    processAppointmentData()
                                }
                            }) {
                                Text("Back to Today")
                                    .font(.subheadline)
                                    .foregroundColor(currentTheme.primary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                            processAppointmentData()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(currentTheme.primary)
                    }
                    
                    Button(action: {
                        withAnimation {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            processAppointmentData()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(currentTheme.primary)
                    }
                }
            }
            
            if appointmentManager.isLoading {
                ProgressView()
                    .frame(height: 220)
            } else {
                Chart(consultationsData) { data in
                    BarMark(
                        x: .value("Hour", data.hourString),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(currentTheme.primary.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 2)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text("\(hour):00")
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(height: 220)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(totalConsultations)")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("\(peakConsultations)")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Peak")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(averageDuration) min")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Avg Time")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .padding()
        .background(currentTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTheme.border, lineWidth: 1)
        )
        .shadow(color: currentTheme.shadow, radius: 10, x: 0, y: 2)
        .padding(.horizontal)
        .onAppear {
            fetchAppointments()
        }
    }
    
    private func fetchAppointments() {
        Task {
            // Use the AppointmentManager to fetch all appointments
            await appointmentManager.fetchAllAppointments()
            processAppointmentData()
        }
    }
    
    private func processAppointmentData() {
        // Create a dictionary to store appointments by hour
        var appointmentsByHour: [Int: [AppointmentData]] = [:]
        
        // Get selected date components
        let calendar = Calendar.current
        let startOfSelectedDate = calendar.startOfDay(for: selectedDate)
        let endOfSelectedDate = calendar.date(byAdding: .day, value: 1, to: startOfSelectedDate)!
        
        // Process each appointment
        for appointment in appointmentManager.allAppointments {
            guard let appointmentDateTime = appointment.appointmentDateTime else {
                // Try to parse from date string if available
                if let dateStr = appointment.date, let dateObj = parseDate(dateStr) {
                    if calendar.isDate(dateObj, inSameDayAs: selectedDate) {
                        // Default to 9 AM if time not specified
                        let hour = 9
                        if appointmentsByHour[hour] == nil {
                            appointmentsByHour[hour] = []
                        }
                        appointmentsByHour[hour]?.append(appointment)
                    }
                }
                continue
            }
            
            // Only include appointments for the selected date
            if appointmentDateTime >= startOfSelectedDate && appointmentDateTime < endOfSelectedDate {
                let hour = calendar.component(.hour, from: appointmentDateTime)
                if appointmentsByHour[hour] == nil {
                    appointmentsByHour[hour] = []
                }
                appointmentsByHour[hour]?.append(appointment)
            }
        }
        
        // Create ConsultationData array
        var newConsultationsData: [ConsultationData] = []
        var totalCount = 0
        var maxCount = 0
        var totalDuration = 0
        
        // Process appointments for each hour (8 AM to 8 PM)
        for hour in 8...20 {
            let appointments = appointmentsByHour[hour] ?? []
            let count = appointments.count
            
            // Use the actual duration from appointments if available, otherwise default to 30
            let totalDurationForHour = appointments.reduce(0) { sum, apt in
                sum + (apt.durationMinutes ?? 30)
            }
            let avgDuration = appointments.isEmpty ? 0 : totalDurationForHour / count
            
            totalCount += count
            maxCount = max(maxCount, count)
            totalDuration += totalDurationForHour
            
            newConsultationsData.append(ConsultationData(
                hour: hour,
                count: count,
                specialty: appointments.first?.doctorName ?? "",
                avgDuration: avgDuration
            ))
        }
        
        // Update the UI
        DispatchQueue.main.async {
            self.consultationsData = newConsultationsData
            self.totalConsultations = totalCount
            self.peakConsultations = maxCount
            self.averageDuration = totalCount > 0 ? totalDuration / totalCount : 0
        }
    }
    
    private func parseDate(_ dateStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateStr)
    }
}

// Extend AppointmentManager to add a method to fetch all appointments
extension AppointmentManager {
    @MainActor
    func fetchAllAppointments() async {
        isLoading = true
        error = nil
        
        do {
            // Use Firestore directly without accessing private properties
            let firestore = Firestore.firestore()
            let appointmentsCollection = "hms4_appointments"
            let snapshot = try await firestore.collection(appointmentsCollection).getDocuments()
            
            var appointments: [AppointmentData] = []
            
            for document in snapshot.documents {
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
                
                // Parse status
                var appointmentStatus: AppointmentData.AppointmentStatus? = nil
                if let statusStr = data["status"] as? String {
                    appointmentStatus = AppointmentData.AppointmentStatus(rawValue: statusStr.uppercased())
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
            
            self.allAppointments = appointments
            self.isLoading = false
            
        } catch {
            self.isLoading = false
            self.error = "Error fetching appointments: \(error.localizedDescription)"
            print("DEBUG: Error fetching all appointments: \(error.localizedDescription)")
        }
    }
}

struct ConsultationData: Identifiable {
    let id = UUID()
    let hour: Int
    let count: Int
    let specialty: String
    let avgDuration: Int
    
    var hourString: String {
        "\(hour)"
    }
}
