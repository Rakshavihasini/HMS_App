//
//  RevenueDetailView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts

struct RevenueDetailView: View {
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
        "Friday"
    }
    
    // MARK: - Helper function for creating the chart
    func revenueChart() -> some View {
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
    }

    var body: some View {
         ScrollView {
             VStack(alignment: .leading, spacing: 16) {
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
    }
}
