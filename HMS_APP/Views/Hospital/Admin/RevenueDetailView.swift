//
//  RevenueDetailView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts
import FirebaseFirestore
import PDFKit
import UIKit

struct RevenueDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var revenueData: [RevenueData] = []
    @State private var isLoading = false
    @State private var selectedTimeRange = TimeRange.week
    @State private var selectedDate = Date()
    @State private var showShareSheet = false
    @State private var pdfURL: URL? = nil
    @State private var isGeneratingPDF = false
    @State private var uniquePatientCount: Int = 0
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var totalRevenue: Int {
        revenueData.reduce(0) { $0 + $1.amount }
    }
    
    var totalPatients: Int {
        uniquePatientCount
    }
    
    var averageRevenuePerPatient: Int {
        totalPatients > 0 ? totalRevenue / totalPatients : 0
    }

    // Create computed properties for the SummaryCard parameters
    var totalRevenueString: String {
        "₹\(totalRevenue.formattedWithSeparator())"
    }

    var totalPatientsString: String {
        "\(totalPatients)"
    }

    var avgRevenuePerPatientString: String {
        "₹\(averageRevenuePerPatient)"
    }

    var peakDay: String {
        if let peakData = revenueData.max(by: { $0.amount < $1.amount }) {
            return peakData.day
        }
        return "-"
    }
    
    // MARK: - Helper function for creating the chart
    func revenueChart() -> some View {
        if isLoading {
            return AnyView(
                ProgressView()
                    .frame(height: 300)
            )
        } else if revenueData.isEmpty {
            return AnyView(
                Text("No revenue data available")
                    .foregroundColor(.gray)
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            )
        } else {
            return AnyView(
                Chart {
                    ForEach(revenueData) { data in
                        LineMark(
                            x: .value("Day", data.day),
                            y: .value("Amount", data.amount)
                        )
                        .foregroundStyle(currentTheme.tertiary.gradient)
                        .symbol {
                            ZStack {
                                Circle()
                                    .fill(currentTheme.card)
                                Circle()
                                    .strokeBorder(currentTheme.tertiary, lineWidth: 2)
                            }
                            .frame(width: 12, height: 12)
                        }
                        
                        AreaMark(
                            x: .value("Day", data.day),
                            y: .value("Amount", data.amount)
                        )
                        .foregroundStyle(currentTheme.tertiary.opacity(0.15).gradient)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let amount = value.as(Int.self) {
                                Text("₹\(amount / 1000)k")
                                    .foregroundColor(currentTheme.text.opacity(0.8))
                            }
                        }
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
            )
        }
    }

    var body: some View {
         ScrollView {
             VStack(alignment: .leading, spacing: 16) {
                 // Header with share button
                 HStack {
                     Text("Revenue Analytics")
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
                         .background(currentTheme.tertiary)
                         .foregroundColor(.white)
                         .cornerRadius(8)
                     }
                     .disabled(isGeneratingPDF)
                     .overlay(
                         isGeneratingPDF ?
                         ProgressView()
                             .progressViewStyle(CircularProgressViewStyle(tint: currentTheme.tertiary))
                             .padding(8)
                         : nil
                     )
                 }
                 .padding(.horizontal)
                 
                 // Time range selector
                TimeRangeSelector(selectedRange: $selectedTimeRange)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _, _ in
                        fetchTransactionData()
                    }
                
                 // Summary cards
                 LazyVGrid(
                     columns: [
                         GridItem(.flexible(minimum: 120, maximum: 200), spacing: 12),
                         GridItem(.flexible(minimum: 120, maximum: 200), spacing: 12)
                     ],
                     spacing: 12
                 ) {
                     SummaryCard(
                         title: "Total Revenue",
                         value: totalRevenueString,
                         icon: "indianrupeesign.circle.fill",
                         color: currentTheme.tertiary
                     )
                     
                     SummaryCard(
                         title: "Patients Served",
                         value: totalPatientsString,
                         icon: "person.2.fill",
                         color: currentTheme.primary
                     )
                     
                     SummaryCard(
                         title: "Avg per Patient",
                         value: avgRevenuePerPatientString,
                         icon: "chart.bar.fill",
                         color: currentTheme.secondary
                     )
                     
                     SummaryCard(
                         title: "Peak Day",
                         value: peakDay,
                         icon: "chart.line.uptrend.xyaxis",
                         color: .purple
                     )
                 }
                 .padding(.horizontal)
                 
                 // Main chart
                 VStack(alignment: .leading, spacing: 12) {
                     Text("Revenue Trend")
                         .font(.headline)
                         .foregroundColor(currentTheme.text)
                     
                     revenueChart()
                 }
                 .padding(.horizontal)
             }
             .padding(.vertical)
        }
        .navigationTitle("Revenue Analytics")
        .navigationBarTitleDisplayMode(.large)
        .background(currentTheme.background.ignoresSafeArea())
        .onAppear {
            fetchTransactionData()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func fetchTransactionData() {
        isLoading = true
        
        // Get date range based on selected time range
        let (startDate, endDate) = getDateRange()
        
        // Date formatter for query and display
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dayFormatter = DateFormatter()
        
        // Set different date format based on time range
        switch selectedTimeRange {
        case .day:
            dayFormatter.dateFormat = "HH:00" // Hour format for day view
        case .week:
            dayFormatter.dateFormat = "E" // Day of week for week view
        case .month:
            dayFormatter.dateFormat = "d" // Day of month for month view
        }
        
        // Initialize tracking variables
        var periodData: [String: (amount: Int, patients: Set<String>)] = [:]
        var uniquePatientIds = Set<String>()
        
        // Query transactions from Firestore
        let db = Firestore.firestore()
        
        Task {
            do {
                let snapshot = try await db.collection("hms4_transactions")
                    .whereField("paymentStatus", isEqualTo: "completed")
                    .getDocuments()
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    // Extract transaction date - prioritize transactionDate over appointmentDate
                    var transactionDate: Date?
                    if let timestamp = data["transactionDate"] as? Timestamp {
                        transactionDate = timestamp.dateValue()
                    } else if let dateString = data["appointmentDate"] as? String {
                        transactionDate = dateFormatter.date(from: dateString)
                    }
                    
                    // Skip if date is not in the selected range
                    guard let date = transactionDate,
                          date >= startDate && date < endDate else {
                        continue
                    }
                    
                    // Extract amount
                    let amount = data["amount"] as? Int ?? 0
                    
                    // Extract patient ID
                    let patientId = data["patientId"] as? String ?? ""
                    
                    // Get period label (hour, day, or month day)
                    let periodLabel = dayFormatter.string(from: date)
                    
                    // Update period data
                    if var periodInfo = periodData[periodLabel] {
                        periodInfo.amount += amount
                        periodInfo.patients.insert(patientId)
                        periodData[periodLabel] = periodInfo
                    } else {
                        periodData[periodLabel] = (amount, [patientId])
                    }
                    
                    // Track unique patients
                    if !patientId.isEmpty {
                        uniquePatientIds.insert(patientId)
                    }
                }
                
                // Convert to RevenueData based on time range
                var newRevenueData: [RevenueData] = []
                
                switch selectedTimeRange {
                case .day:
                    // For day view, show hours from 8AM to 8PM
                    for hour in 8...20 {
                        let hourString = String(format: "%02d:00", hour)
                        let info = periodData[hourString] ?? (0, [])
                        newRevenueData.append(RevenueData(
                            day: hourString,
                            amount: info.amount,
                            patientCount: info.patients.count
                        ))
                    }
                    
                case .week:
                    // For week view, ensure days are in order
                    let weekDayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    for day in weekDayOrder {
                        let info = periodData[day] ?? (0, [])
                        newRevenueData.append(RevenueData(
                            day: day,
                            amount: info.amount,
                            patientCount: info.patients.count
                        ))
                    }
                    
                case .month:
                    // For month view, add entries for each day of the month
                    let calendar = Calendar.current
                    let daysInMonth = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
                    
                    for day in 1...daysInMonth {
                        let dayString = "\(day)"
                        let info = periodData[dayString] ?? (0, [])
                        newRevenueData.append(RevenueData(
                            day: dayString,
                            amount: info.amount,
                            patientCount: info.patients.count
                        ))
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    revenueData = newRevenueData
                    
                    // For all time ranges, use the unique patient IDs count
                    uniquePatientCount = uniquePatientIds.count
                    
                    isLoading = false
                }
            } catch {
                print("Error fetching transaction data: \(error)")
                await MainActor.run {
                    isLoading = false
                    revenueData = [] // Clear data on error
                }
            }
        }
    }
    
    private func getDateRange() -> (Date, Date) {
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .day:
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return (startOfDay, endOfDay)
            
        case .week:
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
            let startOfWeek = calendar.date(from: components)!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: selectedDate)
            let startOfMonth = calendar.date(from: components)!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return (startOfMonth, endOfMonth)
        }
    }
    
    
    // TimeRange enum and TimeRangeSelector moved to SharedModels.swift

    // MARK: - PDF Generation
    private func generatePDFReport() {
        // Create a PDF renderer
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        // Generate a temporary file URL
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = "Revenue_Analytics_\(Date().timeIntervalSince1970).pdf"
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
                let reportTitle = "Revenue Analytics Report"
                let reportTitleRect = CGRect(x: 50, y: 90, width: pageWidth - 100, height: 30)
                reportTitle.draw(in: reportTitleRect, withAttributes: subtitleAttributes)
                
                // Draw date range based on selected time range
                let dateRangeText: String
                switch self.selectedTimeRange {
                case .day:
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    dateRangeText = "Date: \(formatter.string(from: self.selectedDate))"
                case .week:
                    dateRangeText = "Week of \(self.getWeekRangeString())"
                case .month:
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM yyyy"
                    dateRangeText = "Month: \(formatter.string(from: self.selectedDate))"
                }
                
                let dateRangeRect = CGRect(x: 50, y: 120, width: pageWidth - 100, height: 20)
                dateRangeText.draw(in: dateRangeRect, withAttributes: regularAttributes)
                
                // Draw summary statistics
                let summaryTitle = "Summary Statistics"
                let summaryTitleRect = CGRect(x: 50, y: 160, width: pageWidth - 100, height: 20)
                summaryTitle.draw(in: summaryTitleRect, withAttributes: subtitleAttributes)
                
                let totalRevenueText = "Total Revenue: \(self.totalRevenueString)"
                let totalRevenueRect = CGRect(x: 50, y: 190, width: pageWidth - 100, height: 20)
                totalRevenueText.draw(in: totalRevenueRect, withAttributes: regularAttributes)
                
                let totalPatientsText = "Patients Served: \(self.totalPatientsString)"
                let totalPatientsRect = CGRect(x: 50, y: 210, width: pageWidth - 100, height: 20)
                totalPatientsText.draw(in: totalPatientsRect, withAttributes: regularAttributes)
                
                let avgRevenueText = "Average Revenue per Patient: \(self.avgRevenuePerPatientString)"
                let avgRevenueRect = CGRect(x: 50, y: 230, width: pageWidth - 100, height: 20)
                avgRevenueText.draw(in: avgRevenueRect, withAttributes: regularAttributes)
                
                let peakDayText = "Peak Day: \(self.peakDay)"
                let peakDayRect = CGRect(x: 50, y: 250, width: pageWidth - 100, height: 20)
                peakDayText.draw(in: peakDayRect, withAttributes: regularAttributes)
                
                // Draw revenue breakdown by day
                let breakdownTitle = "Revenue Breakdown"
                let breakdownTitleRect = CGRect(x: 50, y: 290, width: pageWidth - 100, height: 20)
                breakdownTitle.draw(in: breakdownTitleRect, withAttributes: subtitleAttributes)
                
                var yPosition = 320.0
                
                for data in self.revenueData {
                    let dayText = "\(data.day): ₹\(data.amount.formattedWithSeparator()) (\(data.patientCount) patients)"
                    let dayRect = CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 20)
                    dayText.draw(in: dayRect, withAttributes: regularAttributes)
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

    // Helper function to get week range string
    private func getWeekRangeString() -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        // Get start of week
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)
        guard let startOfWeek = calendar.date(from: components) else { return "" }
        
        // Get end of week
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else { return "" }
        
        return "\(dateFormatter.string(from: startOfWeek)) - \(dateFormatter.string(from: endOfWeek))"
    }
}
    




