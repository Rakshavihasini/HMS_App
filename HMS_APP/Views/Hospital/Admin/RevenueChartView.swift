//
//  RevenueChartView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts
import FirebaseFirestore

struct RevenueChartView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var revenueData: [RevenueData] = []
    @State private var isLoading = false
    @State private var totalRevenue = 0
    @State private var peakRevenue = 0
    @State private var totalPatients = 0
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Revenue")
                        .font(.headline)
                        .foregroundColor(currentTheme.text)
                    
                    Text("This Week")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                NavigationLink(destination: RevenueDetailView()) {
                    Text("Details")
                        .font(.subheadline.bold())
                        .foregroundColor(currentTheme.tertiary)
                }
            }
            
            if isLoading {
                ProgressView()
                    .frame(height: 220)
            } else {
                Chart(revenueData) { data in
                    LineMark(
                        x: .value("Day", data.day),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(currentTheme.tertiary.gradient)
                    .symbol {
                        Circle()
                            .fill(currentTheme.tertiary)
                            .frame(width: 8, height: 8)
                    }
                    
                    AreaMark(
                        x: .value("Day", data.day),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(currentTheme.tertiary.opacity(0.2).gradient)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        AxisTick()
                        AxisValueLabel {
                            if let amount = value.as(Int.self) {
                                Text("₹\(amount / 1000)k")
                                    .foregroundColor(currentTheme.text.opacity(0.8))
                            }
                        }
                    }
                }
                .frame(height: 220)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("₹\(totalRevenue.formattedWithSeparator())")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("₹\(peakRevenue.formattedWithSeparator())")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Peak")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(totalPatients)")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Patients")
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
            fetchTransactionData()
        }
    }
    
    private func fetchTransactionData() {
        isLoading = true
        
        // Get date range for current week (Monday to Sunday)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let startOfWeek = calendar.date(from: components)!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        // Date formatter for query and display
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E" // e.g., "Mon", "Tue"
        
        // Initialize an array to hold revenue data for each day
        var weeklyRevenueData: [RevenueData] = []
        var dailyAmounts: [String: Int] = [:]
        var dailyPatientCounts: [String: Int] = [:]
        var uniquePatientIds = Set<String>()
        var totalRevenueAmount = 0
        var maxRevenueAmount = 0
        
        // Prepare initial data structure with zero values
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) {
                let dayString = dayFormatter.string(from: date)
                dailyAmounts[dayString] = 0
                dailyPatientCounts[dayString] = 0
            }
        }
        
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
                    
                    // Skip if date is not in current week
                    guard let date = transactionDate,
                          date >= startOfWeek && date < endOfWeek else {
                        continue
                    }
                    
                    // Extract amount
                    let amount = data["amount"] as? Int ?? 0
                    
                    // Extract patient ID
                    if let patientId = data["patientId"] as? String {
                        uniquePatientIds.insert(patientId)
                    }
                    
                    // Get day of week
                    let dayString = dayFormatter.string(from: date)
                    
                    // Update daily amounts and patient counts
                    dailyAmounts[dayString] = (dailyAmounts[dayString] ?? 0) + amount
                    dailyPatientCounts[dayString] = (dailyPatientCounts[dayString] ?? 0) + 1
                    
                    // Update total revenue
                    totalRevenueAmount += amount
                    
                    // Update peak revenue if this day's revenue is higher
                    if let dayAmount = dailyAmounts[dayString], dayAmount > maxRevenueAmount {
                        maxRevenueAmount = dayAmount
                    }
                }
                
                // Create week day order
                let weekDayOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                
                // Convert daily amounts to RevenueData array in correct order
                for day in weekDayOrder {
                    let amount = dailyAmounts[day] ?? 0
                    let patientCount = dailyPatientCounts[day] ?? 0
                    weeklyRevenueData.append(RevenueData(day: day, amount: amount, patientCount: patientCount))
                }
                
                // Update UI on main thread
                await MainActor.run {
                    revenueData = weeklyRevenueData
                    totalRevenue = totalRevenueAmount
                    peakRevenue = maxRevenueAmount
                    totalPatients = uniquePatientIds.count
                    isLoading = false
                }
            } catch {
                print("Error fetching transaction data: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct RevenueData: Identifiable {
    let id = UUID()
    let day: String
    let amount: Int
    let patientCount: Int
}
