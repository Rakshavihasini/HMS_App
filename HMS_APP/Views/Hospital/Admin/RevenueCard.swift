//
//  RevenueCard.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import FirebaseFirestore

struct RevenueCard: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var currentRevenue = 0
    @State private var targetRevenue = 15000 // Default target
    @State private var percentComplete = 0.0
    @State private var isLoading = false
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Revenue")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                    
                    if isLoading {
                        ProgressView()
                            .frame(height: 30)
                    } else {
                        Text("₹\(currentRevenue.formattedWithSeparator())")
                            .font(.title2.bold())
                            .foregroundColor(currentTheme.text)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(currentTheme.secondary, lineWidth: 3)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(percentComplete) / 100)
                        .stroke(currentTheme.tertiary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(currentTheme.tertiary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(percentComplete))% of target")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                    
                    Spacer()
                    
                    Text("₹\(targetRevenue.formattedWithSeparator())")
                        .font(.caption.bold())
                        .foregroundColor(currentTheme.text.opacity(0.8))
                }
                
                ProgressView(value: Double(currentRevenue), total: Double(targetRevenue))
                    .tint(currentTheme.tertiary)
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
            fetchRevenueData()
        }
    }
    
    private func fetchRevenueData() {
        isLoading = true
        
        // Get the current month's date range
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start of the current month
        let components = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: components)!
        
        // Get the end of the current month
        var nextMonthComponents = DateComponents()
        nextMonthComponents.month = 1
        let endOfMonth = calendar.date(byAdding: nextMonthComponents, to: startOfMonth)!
        
        // Firestore reference
        let db = Firestore.firestore()
        
        Task {
            do {
                // Query all completed transactions in the current month
                let snapshot = try await db.collection("hms4_transactions")
                    .whereField("paymentStatus", isEqualTo: "completed")
                    .getDocuments()
                
                var totalRevenue = 0
                var transactionDates: [Date] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    // Extract transaction date
                    var transactionDate: Date?
                    if let dateString = data["appointmentDate"] as? String {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        transactionDate = dateFormatter.date(from: dateString)
                    } else if let timestamp = data["transactionDate"] as? Timestamp {
                        transactionDate = timestamp.dateValue()
                    }
                    
                    // Include only transactions in the current month
                    if let date = transactionDate,
                       date >= startOfMonth && date < endOfMonth {
                        // Add to total revenue
                        if let amount = data["amount"] as? Int {
                            totalRevenue += amount
                        }
                        
                        transactionDates.append(date)
                    }
                }
                
                // Update the UI on the main thread
                await MainActor.run {
                    self.currentRevenue = totalRevenue
                    self.percentComplete = min(100.0, (Double(totalRevenue) / Double(targetRevenue)) * 100)
                    self.isLoading = false
                }
            } catch {
                print("Error fetching revenue data: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    // Set default values in case of error
                    self.currentRevenue = 0
                    self.percentComplete = 0
                }
            }
        }
    }
}

extension Int {
    func formattedWithSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
