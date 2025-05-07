//
//  RevenueDetailView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts
import FirebaseFirestore
import HMS_APP

struct RevenueDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var revenueData: [RevenueData] = []
    @State private var isLoading = false
    @State private var selectedTimeRange = TimeRange.week
    @State private var selectedDate = Date()
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var totalRevenue: Int {
        revenueData.reduce(0) { $0 + $1.amount }
    }
    
    var totalPatients: Int {
        revenueData.reduce(0) { $0 + $1.patientCount }
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
                 // Time range selector
                TimeRangeSelector(selectedRange: $selectedTimeRange)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeRange) { _ in
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
                    
                    // Extract transaction date
                    var transactionDate: Date?
                    if let dateString = data["appointmentDate"] as? String {
                        transactionDate = dateFormatter.date(from: dateString)
                    } else if let timestamp = data["transactionDate"] as? Timestamp {
                        transactionDate = timestamp.dateValue()
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
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            return (startOfWeek, endOfWeek)
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: selectedDate)
            let startOfMonth = calendar.date(from: components)!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            return (startOfMonth, endOfMonth)
        }
    }
}

// TimeRange enum and TimeRangeSelector moved to SharedModels.swift
