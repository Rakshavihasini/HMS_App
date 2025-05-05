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
            fetchTodayAppointments()
        }
    }
    
    private func fetchTodayAppointments() {
        Task {
            await appointmentManager.fetchAppointments()
            processAppointmentData()
        }
    }
    
    private func processAppointmentData() {
        // Create a dictionary to store appointments by hour
        var appointmentsByHour: [Int: [Appointment]] = [:]
        
        // Get selected date components
        let calendar = Calendar.current
        let startOfSelectedDate = calendar.startOfDay(for: selectedDate)
        let endOfSelectedDate = calendar.date(byAdding: .day, value: 1, to: startOfSelectedDate)!
        
        // Process each appointment
        for appointment in appointmentManager.allAppointments {
            guard let appointmentDateTime = appointment.appointmentDateTime else { continue }
            
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
