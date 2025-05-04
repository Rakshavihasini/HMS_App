//
//  PastAppointmentsCalendarView.swift
//  HMS
//
//  Created by Rudra Pruthi on 25/04/25.
//
import SwiftUI

struct PastAppointmentsCalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var doctorManager: DoctorManager
    @StateObject private var appointmentViewModel = Appointment()
    @State private var selectedDate: Date = Date()
    @State private var selectedMonth: Date = Date()
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    // Filter appointments for selected date
    private var appointmentsForSelectedDate: [AppointmentData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDateString = dateFormatter.string(from: selectedDate)
        
        return appointmentViewModel.pastAppointments.filter { appointment in
            appointment.date == selectedDateString
        }
    }
    
    // Get dates with appointments for the calendar view
    private func datesWithAppointments() -> Set<Date> {
        var dates = Set<Date>()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for appointment in appointmentViewModel.pastAppointments {
            if let dateStr = appointment.date, let date = dateFormatter.date(from: dateStr) {
                dates.insert(date)
            }
        }
        
        return dates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar View
            VStack(alignment: .leading) {
                HStack {
                    // Month selector
                    HStack {
                        Button(action: {
                            // Previous month
                            if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
                                selectedMonth = newMonth
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(theme.primary)
                        }
                        
                        Text(monthYearString(from: selectedMonth))
                            .font(.headline)
                            .foregroundColor(theme.primary)
                            .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            // Next month
                            if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
                                selectedMonth = newMonth
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(theme.primary)
                        }
                    }
                    .padding()
                    .background(theme.card)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Days of week
                HStack(spacing: 0) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(theme.secondary)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal)
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    let daysInMonth = daysInMonth(for: selectedMonth)
                    let firstWeekday = firstWeekdayOfMonth(for: selectedMonth)
                    let appointmentDates = datesWithAppointments()
                    
                    // Empty cells for days before the 1st
                    ForEach(0..<firstWeekday-1, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                            .frame(height: 45)
                    }
                    
                    // Days of the month
                    ForEach(1...daysInMonth, id: \.self) { day in
                        let date = dateForDay(day, month: selectedMonth)
                        let hasAppointment = appointmentDates.contains { 
                            Calendar.current.isDate($0, inSameDayAs: date)
                        }
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        
                        CalendarDayView(
                            day: day,
                            isSelected: isSelected,
                            hasAppointment: hasAppointment,
                            theme: theme
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(theme.background)
            
            // Divider between calendar and appointments list
            Divider()
            
            // Appointments list for selected date
            VStack(alignment: .leading) {
                Text("Appointments for \(dayMonthString(from: selectedDate))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                
                if appointmentViewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                } else if appointmentsForSelectedDate.isEmpty {
                    Spacer()
                    Text("No appointments on this date")
                        .foregroundColor(theme.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(appointmentsForSelectedDate) { appointment in
                                ConsultationCard(
                                    appointment: appointment,
                                    onReschedule: {
                                        // Handle reschedule action
                                    },
                                    onStartConsult: {
                                        // Handle consult action
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(theme.background)
        }
        .navigationTitle("Past Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .background(theme.background)
        .task {
            if let userInfo = doctorManager.currentUserInfo, let doctorId = userInfo["id"] as? String {
                await appointmentViewModel.fetchAppointments(for: doctorId)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func dayMonthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }
    
    private func daysInMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    private func firstWeekdayOfMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDay = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDay)
    }
    
    private func dateForDay(_ day: Int, month: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = day
        return calendar.date(from: components)!
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let day: Int
    let isSelected: Bool
    let hasAppointment: Bool
    let theme: Theme
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? theme.primary : Color.clear)
                .frame(height: 40)
            
            Text("\(day)")
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : theme.text)
            
            // Indicator for days with appointments
            if hasAppointment && !isSelected {
                Circle()
//                    .fill(theme.accent)
                    .frame(width: 6, height: 6)
                    .offset(y: 12)
            }
        }
        .frame(height: 45)
    }
}

#Preview {
    PastAppointmentsCalendarView()
        .environmentObject(DoctorManager())
} 
