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
    @State private var selectedTimeRange = TimeRange.day
    @State private var showingFilterSheet = false
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    let consultationsData: [ConsultationData] = [
        .init(hour: 8, count: 5, specialty: "Cardiology", avgDuration: 15),
        .init(hour: 9, count: 8, specialty: "General", avgDuration: 18),
        .init(hour: 10, count: 12, specialty: "Pediatrics", avgDuration: 22),
        .init(hour: 11, count: 9, specialty: "Orthopedics", avgDuration: 25),
        .init(hour: 12, count: 15, specialty: "Neurology", avgDuration: 20),
        .init(hour: 13, count: 10, specialty: "Dermatology", avgDuration: 17),
        .init(hour: 14, count: 7, specialty: "Ophthalmology", avgDuration: 16)
    ]
    
    var totalConsultations: Int {
        consultationsData.reduce(0) { $0 + $1.count }
    }
    
    var avgConsultationDuration: Int {
        let total = consultationsData.reduce(0) { $0 + ($1.avgDuration * $1.count) }
        return total / totalConsultations
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
                            value: "12:00",
                            icon: "chart.line.uptrend.xyaxis",
                            color: currentTheme.primary
                        )
                        
                        SummaryCard(
                            title: "Most Common",
                            value: "General",
                            icon: "stethoscope",
                            color: currentTheme.tertiary
                        )
                    }
                }
                .padding(.horizontal)
                
                // Time range selector
                TimeRangeSelector(selectedRange: $selectedTimeRange)
                    .padding(.horizontal)
                
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
    }
    
    func getSpecialtyBreakdown() -> [(specialty: String, count: Int, percentage: Double)] {
        let specialties = Dictionary(grouping: consultationsData) { $0.specialty }
            .mapValues { data in data.reduce(0) { $0 + $1.count } }
        
        return specialties.map { (specialty, count) in
            let percentage = Double(count) / Double(totalConsultations) * 100
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
