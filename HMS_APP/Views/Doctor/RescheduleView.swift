//
//  TimeSlot.swift
//  HMS_APP
//
//  Created by Rudra Pruthi on 02/05/25.
//


import SwiftUI
import FirebaseFirestore

struct TimeSlot {
    let time: String
    let isAvailable: Bool
}

struct RescheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var appointmentViewModel = Appointment()
    
    let appointment: AppointmentData
    @State private var selectedDate: Date
    @State private var selectedNewTimeSlot: TimeSlot? = nil
    @State private var isRescheduling = false
    @State private var errorMessage: String? = nil
    @State private var showError = false
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    private var formattedDateAndTime: String {
        let dateText = appointment.date ?? "Unknown date"
        return "\(dateText) at \(appointment.time)"
    }
    
    // Define time slots
    let morningTimeSlots = ["9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM", "12:00 PM", "12:30 PM"]
    let afternoonTimeSlots = ["3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM", "5:00 PM", "5:30 PM"]
    
    init(appointment: AppointmentData, initialDate: Date? = nil) {
        self.appointment = appointment
        
        // Set initial date based on passed parameter or appointment data
        var initDate: Date
        if let providedDate = initialDate {
            initDate = providedDate
        } else if let dateObj = appointment.dateObject {
            initDate = dateObj
        } else {
            // Fallback to today
            initDate = Date()
        }
        
        _selectedDate = State(initialValue: initDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Current appointment info
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Appointment").font(.subheadline).foregroundColor(.secondary)
                HStack {
                    VStack(alignment: .leading) {
                        if !appointment.patientName.isEmpty {
                            Text(appointment.patientName).font(.headline)
                                .foregroundColor(theme.text)
                        } else {
                            Text("Patient ID: \(appointment.patientId)").font(.headline)
                                .foregroundColor(theme.text)
                        }
                        Text(formattedDateAndTime)
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    
//                    StatusBadge(status: appointment.status)
                }
            }
            .padding()
            .background(theme.primary.opacity(0.1))
            
            // Date selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Select New Date").font(.headline).foregroundColor(theme.text)
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            calendarStrip
            
            Divider()
            
            // Time slots
            VStack(alignment: .leading, spacing: 8) {
                Text("Select New Time").font(.headline).foregroundColor(theme.text)
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            timeSlotSelectionView
            
            if isRescheduling {
                Spacer()
                ProgressView("Rescheduling appointment...")
                    .padding()
                Spacer()
            }
        }
        .navigationTitle("Reschedule Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .background(theme.background)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveReschedule()
                }
                .disabled(selectedNewTimeSlot == nil || isRescheduling)
                .fontWeight(.semibold)
            }
        }
        .alert("Error", isPresented: $showError, actions: {
            Button("OK") {
                showError = false
                errorMessage = nil
            }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .onChange(of: appointmentViewModel.error) { newError in
            if let error = newError {
                errorMessage = error
                showError = true
            }
        }
    }
    
    var calendarStrip: some View {
        let dates = getNext30Days()
        return VStack(spacing: 0) {
            HStack {
                Text(monthYearString(from: selectedDate)).font(.headline)
                    .foregroundColor(theme.text)
                    .padding(.leading)
                Spacer()
            }.padding(.vertical, 8)
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dates, id: \.self) { date in
                            let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                            let isToday = Calendar.current.isDateInToday(date)
                            Button {
                                withAnimation {
                                    selectedDate = date
                                    selectedNewTimeSlot = nil
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Text(dayOfWeek(from: date)).font(.caption).fontWeight(.medium)
                                        .foregroundColor(isSelected ? .white : .secondary)
                                    Text("\(Calendar.current.component(.day, from: date))").font(.headline).fontWeight(.bold)
                                        .foregroundColor(isSelected ? .white : isToday ? theme.primary : theme.text)
                                    // No indicator since we don't have appointments data yet
                                    Circle().fill(Color.clear)
                                        .frame(width: 4, height: 4)
                                }
                                .frame(width: 60, height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? theme.primary : isToday ? theme.primary.opacity(0.1) : Color.clear)
                                )
                            }
                            .id(date)
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    scrollProxy.scrollTo(selectedDate, anchor: .center)
                }
            }
        }
        .padding(.vertical, 8)
        .background(theme.card)
    }
    
    var timeSlotSelectionView: some View {
        let availableSlots = availableTimeSlotsForDate(selectedDate)
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Morning
                VStack(alignment: .leading, spacing: 12) {
                    Text("Morning (9:00 AM - 12:30 PM)").font(.headline).foregroundColor(.secondary).padding(.horizontal)
                    let morningSlots = availableSlots.filter { morningTimeSlots.contains($0.time) }
                    if morningSlots.isEmpty {
                        Text("No available morning slots").font(.subheadline).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center).padding()
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(morningSlots, id: \.time) { slot in
                                TimeSlotButton(
                                    timeSlot: slot,
                                    isSelected: selectedNewTimeSlot?.time == slot.time,
                                    theme: theme
                                ) {
                                    if slot.isAvailable { selectedNewTimeSlot = slot }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Afternoon
                VStack(alignment: .leading, spacing: 12) {
                    Text("Afternoon (3:00 PM - 5:30 PM)").font(.headline).foregroundColor(.secondary).padding(.horizontal)
                    let afternoonSlots = availableSlots.filter { afternoonTimeSlots.contains($0.time) }
                    if afternoonSlots.isEmpty {
                        Text("No available afternoon slots").font(.subheadline).foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center).padding()
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(afternoonSlots, id: \.time) { slot in
                                TimeSlotButton(
                                    timeSlot: slot,
                                    isSelected: selectedNewTimeSlot?.time == slot.time,
                                    theme: theme
                                ) {
                                    if slot.isAvailable { selectedNewTimeSlot = slot }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Helper Functions
    private func saveReschedule() {
        guard let selectedSlot = selectedNewTimeSlot, selectedSlot.isAvailable else { return }
        
        isRescheduling = true
        
        // Combine date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        // Parse the time slot
        dateFormatter.dateFormat = "h:mm a"
        if let timeDate = dateFormatter.date(from: selectedSlot.time) {
            dateFormatter.dateFormat = "HH:mm"
            let hour = dateFormatter.string(from: timeDate)
            
            // Create a combined date
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let newAppointmentDate = dateFormatter.date(from: "\(dateString) \(hour)") {
                // Use Appointment to reschedule
                Task {
                    let success = await appointmentViewModel.rescheduleAppointment(
                        appointmentId: appointment.id,
                        newDate: newAppointmentDate
                    )
                    
                    DispatchQueue.main.async {
                        self.isRescheduling = false
                        if success {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            } else {
                isRescheduling = false
                errorMessage = "Invalid date format. Please try again."
                showError = true
            }
        } else {
            isRescheduling = false
            errorMessage = "Invalid time format. Please try again."
            showError = true
        }
    }
    
    func availableTimeSlotsForDate(_ date: Date) -> [TimeSlot] {
        // For simplicity, we'll make all slots available except the current appointment's time
        // when viewing the current appointment's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Check if the selected date matches the appointment date
        let isCurrentAppointmentDate = appointment.date == dateString
        
        // Combine both time slots
        let allTimeSlots = morningTimeSlots + afternoonTimeSlots
        
        return allTimeSlots.map { time in
            // Check if this is the current appointment time
            let isCurrentTime = isCurrentAppointmentDate && time == appointment.time
            return TimeSlot(time: time, isAvailable: !isCurrentTime)
        }
    }
    
    func getNext30Days() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<30).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: today)
        }
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    func formattedDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct TimeSlotButton: View {
    let timeSlot: TimeSlot
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeSlot.time)
                .foregroundColor(getForegroundColor())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(getBackgroundColor())
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(getBorderColor(), lineWidth: 1)
                )
        }
        .disabled(!timeSlot.isAvailable)
    }
    
    private func getForegroundColor() -> Color {
        if !timeSlot.isAvailable {
            return .gray
        }
        return isSelected ? .white : theme.primary
    }
    
    private func getBackgroundColor() -> Color {
        if !timeSlot.isAvailable {
            return Color.gray.opacity(0.1)
        }
        return isSelected ? theme.primary : Color.clear
    }
    
    private func getBorderColor() -> Color {
        if !timeSlot.isAvailable {
            return Color.gray.opacity(0.3)
        }
        return isSelected ? theme.primary : theme.primary.opacity(0.5)
    }
}

#Preview {
    NavigationStack {
        RescheduleView(appointment: Appointment.sampleAppointments()[0])
    }
}
