//
//  ConsultationDetailView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts
import PDFKit
import UIKit

struct ConsultationDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var appointmentManager = AppointmentManager()
    @State private var selectedTimeRange = TimeRange.day
    @State private var showingFilterSheet = false
    @State private var selectedDate: Date = Date()
    @State private var consultationsData: [ConsultationData] = []
    @State private var showShareSheet = false
    @State private var pdfURL: URL? = nil
    @State private var isGeneratingPDF = false
    
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
                    HStack {
                        Text("Consultation Analytics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(currentTheme.text)
                        
                        Spacer()
                        
                        Button(action: {
                            isGeneratingPDF = true
                            generatePDFReport()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(currentTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isGeneratingPDF)
                        .overlay(
                            isGeneratingPDF ?
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: currentTheme.primary))
                                .padding(8)
                            : nil
                        )
                    }
                    
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
        .onChange(of: selectedTimeRange) { oldValue, newValue in
            processAppointmentData()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func fetchAppointments() {
        Task {
            await appointmentManager.fetchAllAppointments()
            processAppointmentData()
        }
    }
    
    private func processAppointmentData() {
        var appointmentsByHour: [Int: [AppointmentData]] = [:]
        let calendar = Calendar.current
        
        // Get date range based on selected time range
        let (startDate, endDate) = getDateRange()
        
        print("DEBUG: Processing appointments for range: \(startDate) to \(endDate)")
        print("DEBUG: Total appointments available: \(appointmentManager.allAppointments.count)")
        
        // Process each appointment
        for appointment in appointmentManager.allAppointments {
            // Check if appointment is within the selected date range
            guard let appointmentDateTime = getAppointmentDateTime(appointment, calendar) else {
                continue
            }
            
            if appointmentDateTime >= startDate && appointmentDateTime < endDate {
                print("DEBUG: Processing appointment at \(appointmentDateTime)")
                
                // Normalize hours to working hours
                var hour = calendar.component(.hour, from: appointmentDateTime)
                
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
    
    // Helper function to get appointment date time consistently
    private func getAppointmentDateTime(_ appointment: AppointmentData, _ calendar: Calendar) -> Date? {
        if let appointmentDateTime = appointment.appointmentDateTime {
            return appointmentDateTime
        }
        
        // Try to parse from date string if available
        if let dateStr = appointment.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let dateObj = formatter.date(from: dateStr) {
                // If we only have a date, default to 9 AM
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dateObj)
            }
        }
        
        return nil
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
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: endDate) ?? endDate))"
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
    
    private func getSpecialtyBreakdown() -> [(specialty: String, count: Int, percentage: Double)] {
        // Group appointments by doctor name
        let specialties = Dictionary(grouping: appointmentManager.allAppointments) { $0.doctorName }
            .mapValues { $0.count }
        
        let total = specialties.values.reduce(0, +)
        
        // Create an array of tuples with specialty, count, and percentage
        return specialties.map { (specialty, count) in
            let percentage = total > 0 ? (Double(count) / Double(total) * 100) : 0
            return (specialty: specialty, count: count, percentage: percentage)
        }
        .sorted { $0.count > $1.count } // Sort by count descending
    }
    
    // MARK: - PDF Generation
    private func generatePDFReport() {
        // Create a PDF renderer
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // Generate a temporary file URL
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = "Consultation_Analytics_\(Date().timeIntervalSince1970).pdf"
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try renderer.writePDF(to: fileURL) { context in
                context.beginPage()
                
                // Draw content on the PDF page
                let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
                let subtitleFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
                let regularFont = UIFont.systemFont(ofSize: 12, weight: .regular)
                
                // Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor.black
                ]
                
                let subtitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: subtitleFont,
                    .foregroundColor: UIColor.black
                ]
                
                let regularAttributes: [NSAttributedString.Key: Any] = [
                    .font: regularFont,
                    .foregroundColor: UIColor.black
                ]
                
                // Draw hospital logo or name
                let hospitalName = "HMS Hospital"
                let hospitalNameRect = CGRect(x: 50, y: 50, width: pageWidth - 100, height: 30)
                hospitalName.draw(in: hospitalNameRect, withAttributes: titleAttributes)
                
                // Draw report title
                let reportTitle = "Consultation Analytics Report"
                let reportTitleRect = CGRect(x: 50, y: 90, width: pageWidth - 100, height: 30)
                reportTitle.draw(in: reportTitleRect, withAttributes: subtitleAttributes)
                
                // Draw date range
                let dateRangeText = "Period: \(getDateRangeText())"
                let dateRangeRect = CGRect(x: 50, y: 120, width: pageWidth - 100, height: 20)
                dateRangeText.draw(in: dateRangeRect, withAttributes: regularAttributes)
                
                // Draw summary statistics
                let summaryTitle = "Summary Statistics"
                let summaryTitleRect = CGRect(x: 50, y: 160, width: pageWidth - 100, height: 20)
                summaryTitle.draw(in: summaryTitleRect, withAttributes: subtitleAttributes)
                
                let totalConsultationsText = "Total Consultations: \(totalConsultations)"
                let totalConsultationsRect = CGRect(x: 50, y: 190, width: pageWidth - 100, height: 20)
                totalConsultationsText.draw(in: totalConsultationsRect, withAttributes: regularAttributes)
                
                let avgDurationText = "Average Duration: \(avgConsultationDuration) minutes"
                let avgDurationRect = CGRect(x: 50, y: 210, width: pageWidth - 100, height: 20)
                avgDurationText.draw(in: avgDurationRect, withAttributes: regularAttributes)
                
                let peakHourText = "Peak Hour: \(peakHour)"
                let peakHourRect = CGRect(x: 50, y: 230, width: pageWidth - 100, height: 20)
                peakHourText.draw(in: peakHourRect, withAttributes: regularAttributes)
                
                let mostCommonText = "Most Common Specialty: \(mostCommonSpecialty)"
                let mostCommonRect = CGRect(x: 50, y: 250, width: pageWidth - 100, height: 20)
                mostCommonText.draw(in: mostCommonRect, withAttributes: regularAttributes)
                
                // Draw specialty breakdown
                let breakdownTitle = "Specialty Breakdown"
                let breakdownTitleRect = CGRect(x: 50, y: 290, width: pageWidth - 100, height: 20)
                breakdownTitle.draw(in: breakdownTitleRect, withAttributes: subtitleAttributes)
                
                let specialtyBreakdown = getSpecialtyBreakdown()
                var yPosition = 320.0
                
                for item in specialtyBreakdown {
                    let specialtyText = "\(item.specialty): \(item.count) consultations (\(Int(item.percentage))%)"
                    let specialtyRect = CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 20)
                    specialtyText.draw(in: specialtyRect, withAttributes: regularAttributes)
                    yPosition += 20
                }
                
                // Draw footer with date
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                let footerText = "Generated on \(dateFormatter.string(from: Date()))"
                let footerRect = CGRect(x: 50, y: pageHeight - 50, width: pageWidth - 100, height: 20)
                footerText.draw(in: footerRect, withAttributes: regularAttributes)
            }
            
            // Set the PDF URL and show share sheet
            self.pdfURL = fileURL
            self.isGeneratingPDF = false
            self.showShareSheet = true
            
        } catch {
            print("Error generating PDF: \(error)")
            self.isGeneratingPDF = false
        }
    }

//    // Helper function to get date range text
//    private func getDateRangeText() -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .medium
//        
//        switch selectedTimeRange {
//        case .day:
//            return dateFormatter.string(from: selectedDate)
//        case .week:
//            let calendar = Calendar.current
//            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
//            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
//            return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
//        case .month:
//            dateFormatter.dateFormat = "MMMM yyyy"
//            return dateFormatter.string(from: selectedDate)
//        }
//    }

//    // Helper function to get specialty breakdown
//    private func getSpecialtyBreakdown() -> [(specialty: String, count: Int, percentage: Double)] {
//        // Count appointments by specialty
//        var specialtyCounts: [String: Int] = [:]
//        
//        for appointment in appointmentManager.appointments {
//            let specialty = appointment.doctorSpecialty
//            specialtyCounts[specialty, default: 0] += 1
//        }
//        
//        // Convert to array and calculate percentages
//        let total = appointmentManager.appointments.count
//        var result: [(specialty: String, count: Int, percentage: Double)] = []
//        
//        for (specialty, count) in specialtyCounts {
//            let percentage = total > 0 ? Double(count) / Double(total) * 100.0 : 0
//            result.append((specialty: specialty, count: count, percentage: percentage))
//        }
//        
//        // Sort by count (descending)
//        return result.sorted { $0.count > $1.count }
//    }
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




