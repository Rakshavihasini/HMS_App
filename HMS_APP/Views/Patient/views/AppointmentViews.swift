import SwiftUI
import FirebaseFirestore

// MARK: - Shared Appointment Views
struct AppointmentDetailView: View {
    let appointment: AppointmentData
    @Binding var showRescheduleModal: Bool
    let onCancel: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    init(appointment: AppointmentData, showRescheduleModal: Binding<Bool>, onCancel: @escaping () -> Void) {
        self.appointment = appointment
        self._showRescheduleModal = showRescheduleModal
        self.onCancel = onCancel
        
        print("DEBUG: AppointmentDetailView initialized with appointment ID: " + appointment.id)
        print("DEBUG: Doctor: \(appointment.doctorName), Date: \(formattedDate)")
    }
    
    var statusColor: Color {
        guard let status = appointment.status else {
            return .gray
        }
        
        switch status {
        case .scheduled, .rescheduled: return .medicareBlue
        case .inProgress: return .medicareGreen
        case .completed: return .gray
        case .cancelled, .noShow: return .medicareRed
        }
    }
    
    var formattedDate: String {
        guard let dateTime = appointment.appointmentDateTime else {
            return "Not scheduled"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.string(from: dateTime)
    }
    
    var formattedTime: String {
        guard let dateTime = appointment.appointmentDateTime else {
            return "Not scheduled"
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: dateTime)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Appointment header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appointment.doctorName)
                                .font(.title2)
                                .bold()
                            
                            if let notes = appointment.notes {
                                Text(notes)
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        if let status = appointment.status {
                            Text(status.rawValue)
                                .font(.subheadline)
                                .foregroundColor(statusColor)
                                .padding(8)
                                .background(statusColor.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .onAppear {
                        print("DEBUG: AppointmentDetailView header appeared")
                    }
                    
                    // Appointment details
                    VStack(alignment: .leading, spacing: 15) {
                        DetailRow(icon: "calendar", title: "Date", value: formattedDate)
                        DetailRow(icon: "clock", title: "Time", value: formattedTime)
                        DetailRow(icon: "stethoscope", title: "Doctor", value: appointment.doctorName)
                        
                        if let notes = appointment.notes {
                            DetailRow(icon: "doc.text", title: "Reason", value: notes)
                        }
                        
                        if let duration = appointment.durationMinutes {
                            DetailRow(icon: "timer", title: "Duration", value: "\(duration) minutes")
                        }
                    }
                    .padding()
                    .onAppear {
                        print("DEBUG: AppointmentDetailView details appeared")
                    }
                    
                    // Action buttons
                    if appointment.status == .scheduled || appointment.status == .rescheduled || appointment.status == .inProgress {
                        VStack(spacing: 15) {
                            Button(action: {
                                print("DEBUG: Reschedule button pressed")
                                showRescheduleModal = true
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Reschedule Appointment")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.medicareBlue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                print("DEBUG: Cancel appointment button pressed")
                                onCancel()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Cancel Appointment")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.medicareRed.opacity(0.1))
                                .foregroundColor(.medicareRed)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Appointment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Close") {
                        print("DEBUG: Close button pressed in AppointmentDetailView")
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                print("DEBUG: Entire AppointmentDetailView appeared")
            }
            .onDisappear {
                print("DEBUG: AppointmentDetailView disappeared")
            }
        }
    }
}

struct AppointmentRescheduleView: View {
    let appointment: AppointmentData
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDate = Date()
    @State private var selectedTime = "09:00 AM"
    @State private var isLoading = false
    @State private var showingConfirmation = false
    @EnvironmentObject var appointmentManager: AppointmentManager
    
    let timeSlots = ["09:00 AM", "09:30 AM", "10:00 AM",
                      "10:30 AM", "11:00 AM", "11:30 AM",
                      "03:00 PM", "03:30 PM", "04:00 PM",
                      "04:30 PM", "05:00 PM", "05:30 PM"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Current Appointment")) {
                    if let dateTime = appointment.appointmentDateTime {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.medicareBlue)
                            Text(dateTime.formatted(date: .abbreviated, time: .omitted))
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.medicareBlue)
                            Text(dateTime.formatted(date: .omitted, time: .shortened))
                        }
                    } else {
                        Text("No date/time information available")
                    }
                }
                
                Section(header: Text("New Date and Time")) {
                    DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                    
                    Picker("Time", selection: $selectedTime) {
                        ForEach(timeSlots, id: \.self) { time in
                            Text(time).tag(time)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button(action: rescheduleAppointment) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Confirm Reschedule")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .listRowBackground(Color.medicareBlue)
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Appointment Rescheduled"),
                    message: Text("Your appointment has been rescheduled successfully."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .onAppear {
                print("DEBUG: AppointmentRescheduleView appeared")
                if let dateTime = appointment.appointmentDateTime {
                    selectedDate = dateTime
                    
                    // Try to match the current time to one of our time slots
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "hh:mm a"
                    let currentTimeString = timeFormatter.string(from: dateTime)
                    
                    if timeSlots.contains(currentTimeString) {
                        selectedTime = currentTimeString
                    }
                }
            }
        }
    }
    
    private func rescheduleAppointment() {
        isLoading = true
        
        // Combine date and time into a single Date object
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm a"
        
        // Format date as string
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateOnlyFormatter.string(from: selectedDate)
        
        // Create a combined date time string
        let dateTimeString = "\(dateString) \(selectedTime)"
        
        // Parse the combined string into a Date
        if let newDateTime = dateFormatter.date(from: dateTimeString) {
            // Update Firebase using the new Date object
            Task {
                do {
                    try await appointmentManager.rescheduleAppointment(
                        appointmentId: appointment.id,
                        newDate: newDateTime
                    )
                    
                    await MainActor.run {
                        isLoading = false
                        showingConfirmation = true
                    }
                } catch {
                    print("Error rescheduling: \(error)")
                    isLoading = false
                }
            }
        } else {
            print("Error creating date from string: \(dateTimeString)")
            isLoading = false
        }
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.medicareBlue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
}
