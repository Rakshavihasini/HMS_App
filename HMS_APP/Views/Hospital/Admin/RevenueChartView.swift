//
//  RevenueChartView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts

struct RevenueChartView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    let revenueData: [RevenueData] = [
        .init(day: "Mon", amount: 8500, patientCount: 42),
        .init(day: "Tue", amount: 10200, patientCount: 51),
        .init(day: "Wed", amount: 12500, patientCount: 63),
        .init(day: "Thu", amount: 9800, patientCount: 47),
        .init(day: "Fri", amount: 15000, patientCount: 78),
        .init(day: "Sat", amount: 7500, patientCount: 38),
        .init(day: "Sun", amount: 5000, patientCount: 25)
    ]
    
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
            
            HStack {
                VStack(alignment: .leading) {
                    Text("₹68,500")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("₹15,000")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Peak")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("344")
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
    }
}

struct RevenueData: Identifiable {
    let id = UUID()
    let day: String
    let amount: Int
    let patientCount: Int
}
