//
//  ConsultationDetailView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts

struct ConsultationDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var appointmentManager = AppointmentManager()
    @State private var selectedTimeRange = TimeRange.day
    @State private var showingFilterSheet = false
    @State private var selectedDate: Date = Date()
    @State private var consultationsData: [ConsultationData] = []
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var totalConsultations: Int {
        consultationsData.reduce(0) { $0 + $1.count }
    }
    
    var avgConsultationDuration: Int {
        let total = consultationsData.reduce(0) { $0 + ($1.avgDuration * $1.count) }
        return totalConsultations > 0 ? total / totalConsultations : 0
    }
    
    var peakHour: String {
        if let peak = consultationsData.max(by: { $0.count < $1.count }) {
            return "\(peak.hour):00"
        }
        return "N/A"
    }
    
    var mostCommonSpecialty: String {
        let specialtyCounts = Dictionary(grouping: appointmentManager.allAppointments) { $0.doctorName }
            .mapValues { $0.count }
        if let mostCommon = specialtyCounts.max(by: { $0.value < $1.value }) {
            return mostCommon.key
        }
        return "N/A"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Summary cards
                VStack(spacing: 16) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                        SummaryCard(
                            title: "Total Consultations",
                            value: "\(totalConsultations)",
                            icon: "person.2.fill",
                            color: currentTheme.primary
                        )
                        
                        SummaryCard(
                            title: "Avg Duration",
                            value: "\(avgConsultationDuration) min",
                            icon: "clock.fill",
                            color: currentTheme.tertiary
                        )
                        
                        SummaryCard(
                            title: "Peak Hour",
                            value: peakHour,
                            icon: "chart.line.uptrend.xyaxis",
                            color: currentTheme.primary
                        )
                        
                        SummaryCard(
                            title: "Most Common",
                            value: mostCommonSpecialty,
                            icon: "stethoscope",
                            color: currentTheme.tertiary
                        )
                    }
                }
                .padding(.horizontal)
                
                // Time range selector with date navigation
                VStack(spacing: 8) {
                    TimeRangeSelector(selectedRange: $selectedTimeRange)
                    
                    HStack {
                        Button(action: {
                            moveDateBackward()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(currentTheme.primary)
                        }
                        
                        Spacer()
                        
                        Text(getDateRangeText())
                            .font(.subheadline)
                            .foregroundColor(currentTheme.text)
                        
                        Spacer()
                        
                        Button(action: {
                            moveDateForward()
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(currentTheme.primary)
                        }
                    }
                }
                .padding(.horizontal)
                
                if appointmentManager.isLoading {
                    ProgressView()
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                } else {
                    // Main chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Consultations by Hour")
                                .font(.headline)
                                .foregroundColor(currentTheme.text)
                            
                            Spacer()
                            
                            Button(action: { showingFilterSheet = true }) {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                            .tint(currentTheme.primary)
                        }
                        
                        Chart(consultationsData) { data in
                            BarMark(
                                x: .value("Hour", data.hourString),
                                y: .value("Count", data.count)
                            )
                            .foregroundStyle(currentTheme.primary.gradient)
                            .cornerRadius(8)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: 1)) { value in
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
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel()
                            }
                        }
                        .frame(height: 300)
                        .padding()
                        .background(currentTheme.card)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(currentTheme.border, lineWidth: 1)
                        )
                        .shadow(color: currentTheme.shadow, radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                }
                
                // Consultations breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Breakdown by Specialty")
                        .font(.headline)
                        .foregroundColor(currentTheme.text)
                    
                    ForEach(getSpecialtyBreakdown(), id: \.specialty) { item in
                        HStack {
                            Text(item.specialty)
                                .font(.subheadline)
                                .foregroundColor(currentTheme.text)
                            
                            Spacer()
                            
                            Text("\(item.count)")
                                .font(.subheadline.bold())
                                .foregroundColor(currentTheme.text)
                            
                            Text("(\(Int(item.percentage))%)")
                                .foregroundColor(currentTheme.text.opacity(0.6))
                                .font(.caption)
                        }
                        .padding()
                        .background(currentTheme.card)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(currentTheme.border, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Consultation Analytics")
        .navigationBarTitleDisplayMode(.large)
        .background(currentTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showingFilterSheet) {
            FilterView()
        }
        .onAppear {
            fetchAppointments()
        }
        .onChange(of: selectedTimeRange) { _ in
            processAppointmentData()
        }
    }
    
    private func fetchAppointments() {
        Task {
            await appointmentManager.fetchAppointments()
            processAppointmentData()
        }
    }
    
    private func processAppointmentData() {
        var appointmentsByHour: [Int: [Appointment]] = [:]
        let calendar = Calendar.current
        
        // Get date range based on selected time range
        let (startDate, endDate) = getDateRange()
        
        print("DEBUG: Processing appointments for range: \(startDate) to \(endDate)")
        print("DEBUG: Total appointments available: \(appointmentManager.allAppointments.count)")
        
        // First try to get appointments for the selected period
        for appointment in appointmentManager.patientAppointments {
            guard let appointmentDateTime = appointment.appointmentDateTime else {
                print("DEBUG: Appointment has no datetime")
                continue
            }
            
            print("DEBUG: Processing appointment at \(appointmentDateTime)")
            
            // For any view (day/week/month), include both past and upcoming appointments
            var hour = calendar.component(.hour, from: appointmentDateTime)
            
            // Normalize hours to working hours
            if hour < 8 {
                hour = 8
            } else if hour > 20 {
                hour = 20
            }
            
            if appointmentsByHour[hour] == nil {
                appointmentsByHour[hour] = []
            }
            appointmentsByHour[hour]?.append(appointment)
        }
        
        print("DEBUG: Appointments by hour: \(appointmentsByHour.mapValues { $0.count })")
        
        // Create ConsultationData array
        var newConsultationsData: [ConsultationData] = []
        
        // Process appointments for each hour (8 AM to 8 PM)
        for hour in 8...20 {
            let appointments = appointmentsByHour[hour] ?? []
            let count = appointments.count
            let totalDuration = appointments.reduce(0) { $0 + ($1.durationMinutes ?? 30) }
            let avgDuration = count > 0 ? totalDuration / count : 0
            
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
            print("DEBUG: Updated consultations data with \(newConsultationsData.count) entries")
        }
    }
    
    private func getDateRange() -> (Date, Date) {
        let calendar = Calendar.current
        let now = selectedDate
        
        switch selectedTimeRange {
        case .day:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
            
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: components)!
            var nextMonthComponents = DateComponents()
            nextMonthComponents.month = 1
            let endOfMonth = calendar.date(byAdding: nextMonthComponents, to: startOfMonth)!
            return (startOfMonth, endOfMonth)
        }
    }
    
    private func getDateRangeText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        
        let (startDate, endDate) = getDateRange()
        
        switch selectedTimeRange {
        case .day:
            return formatter.string(from: selectedDate)
        case .week:
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: selectedDate)
        }
    }
    
    private func moveDateForward() {
        let calendar = Calendar.current
        switch selectedTimeRange {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
        processAppointmentData()
    }
    
    private func moveDateBackward() {
        let calendar = Calendar.current
        switch selectedTimeRange {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
        processAppointmentData()
    }
    
    func getSpecialtyBreakdown() -> [(specialty: String, count: Int, percentage: Double)] {
        let specialties = Dictionary(grouping: appointmentManager.allAppointments) { $0.doctorName }
            .mapValues { $0.count }
        
        let total = specialties.values.reduce(0, +)
        
        return specialties.map { (specialty, count) in
            let percentage = total > 0 ? (Double(count) / Double(total) * 100) : 0
            return (specialty: specialty, count: count, percentage: percentage)
        }.sorted { $0.count > $1.count }
    }
}

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            Text("Day").tag(TimeRange.day)
            Text("Week").tag(TimeRange.week)
            Text("Month").tag(TimeRange.month)
        }
        .pickerStyle(.segmented)
        .tint(currentTheme.primary)
    }
}

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedSpecialties = Set<String>()
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    let specialties = ["All", "Cardiology", "General", "Pediatrics", "Orthopedics",
                       "Neurology", "Dermatology", "Ophthalmology"]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Specialty")) {
                    ForEach(specialties, id: \.self) { specialty in
                        Button(action: {
                            if specialty == "All" {
                                if selectedSpecialties.contains("All") {
                                    selectedSpecialties.removeAll()
                                } else {
                                    selectedSpecialties = Set(specialties)
                                }
                            } else {
                                if selectedSpecialties.contains(specialty) {
                                    selectedSpecialties.remove(specialty)
                                } else {
                                    selectedSpecialties.insert(specialty)
                                }
                            }
                        }) {
                            HStack {
                                Text(specialty)
                                    .foregroundColor(currentTheme.text)
                                Spacer()
                                if selectedSpecialties.contains(specialty) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(currentTheme.primary)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(currentTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(currentTheme.primary)
                }
            }
        }
    }
}

enum TimeRange {
    case day, week, month
}
