//
//  ConsultationsChartView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//


import SwiftUI
import Charts

struct ConsultationsChartView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    let consultationsData: [ConsultationData] = [
        .init(hour: 8, count: 5, specialty: "General", avgDuration: 15),
        .init(hour: 9, count: 8, specialty: "General", avgDuration: 18),
        .init(hour: 10, count: 12, specialty: "Pediatrics", avgDuration: 20),
        .init(hour: 11, count: 9, specialty: "Cardiology", avgDuration: 25),
        .init(hour: 12, count: 15, specialty: "Neurology", avgDuration: 22),
        .init(hour: 13, count: 10, specialty: "Dermatology", avgDuration: 17),
        .init(hour: 14, count: 7, specialty: "General", avgDuration: 15)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Consultations")
                        .font(.headline)
                        .foregroundColor(currentTheme.text)
                    
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                NavigationLink(destination: ConsultationDetailView()) {
                    Text("Details")
                        .font(.subheadline.bold())
                        .foregroundColor(currentTheme.primary)
                }
            }
            
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
            
            HStack {
                VStack(alignment: .leading) {
                    Text("66")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("15")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    Text("Peak")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("19 min")
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
