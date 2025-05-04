//
//  BookAppointmentView.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//

import SwiftUI
import FirebaseFirestore

struct BookAppointmentView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    let doctor: DoctorProfile
    let patient: Patient
    @State private var selectedDate = Date()
    @State private var reason = ""
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    // Default time slots that will be filtered based on doctor availability
    let defaultTimeSlots = ["09:00 AM", "09:30 AM", "10:00 AM",
                           "10:30 AM", "11:00 AM", "11:30 AM",
                           "03:00 PM", "03:30 PM", "04:00 PM",
                           "04:30 PM", "05:00 PM", "05:30 PM"]
    
    @State private var availableTimeSlots: [String] = []
    @State private var selectedTime = "09:00 AM"
    
    // Default appointment duration in minutes
    private let appointmentDuration = 30
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DoctorInfoHeader(doctor: doctor)
                    
                    DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .tint(.medicareBlue)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .onChange(of: selectedDate) { _ in
                            fetchAvailableTimeSlots()
                        }
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                    } else if availableTimeSlots.isEmpty {
                        Text("No available time slots for this date")
                            .foregroundColor(.red)
                    } else {
                        Picker("Time", selection: $selectedTime) {
                            ForEach(availableTimeSlots, id: \.self) { time in
                                Text(time).tag(time)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    TextField("Reason for visit", text: $reason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } header: {
                    Text("Appointment Details")
                }
                
                Section {
                    Button(action: bookAppointment) {
                        Text("Confirm Appointment")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .bold()
                    }
                    .disabled(isLoading || availableTimeSlots.isEmpty)
                    .listRowBackground(Color.medicareBlue)
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Appointment Booked"),
                    message: Text("Your appointment with \(doctor.name) on \(formattedDate()) at \(selectedTime) has been confirmed."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                fetchAvailableTimeSlots()
            }
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    private func fetchAvailableTimeSlots() {
        isLoading = true
        
        // Format the selected date to match Firebase date format (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        // Reset available time slots
        availableTimeSlots = defaultTimeSlots
        
        // Check if doctor has this day as a full day leave
        if let fullDayLeaves = doctor.schedules?.fullDayLeaves,
           fullDayLeaves[dateString] != nil {
            // Doctor is on leave for the entire day
            availableTimeSlots = []
            isLoading = false
            return
        }
        
        // Filter out any time slots the doctor has marked as unavailable
        if let leaveTimeSlots = doctor.schedules?.leaveTimeSlots?[dateString] {
            for (timeSlot, _) in leaveTimeSlots {
                availableTimeSlots.removeAll { $0 == timeSlot }
            }
        }
        
        // Also check for existing appointments on this date to avoid double booking
        Task {
            do {
                let snapshot = try await db.collection("\(dbName)_appointments")
                    .whereField("doctorId", isEqualTo: doctor.id ?? "")
                    .whereField("date", isEqualTo: dateString)
                    .getDocuments()
                
                for document in snapshot.documents {
                    if let bookedTime = document.data()["time"] as? String {
                        // Remove already booked time slots
                        availableTimeSlots.removeAll { $0 == bookedTime }
                    }
                }
                
                // If no time slots are available, set selectedTime to empty
                if availableTimeSlots.isEmpty {
                    selectedTime = ""
                } else if !availableTimeSlots.contains(selectedTime) {
                    // If currently selected time is no longer available, select the first available
                    selectedTime = availableTimeSlots.first ?? ""
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to fetch time slots: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func bookAppointment() {
        guard let doctorId = doctor.id,
              !reason.isEmpty else {
            errorMessage = "Missing information. Please ensure all fields are filled."
            showingError = true
            return
        }
        
        isLoading = true
        
        // Format date as string for storage (for backward compatibility)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        // Create a combined date and time for appointmentDateTime
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd h:mm a"
        let combinedDateTimeString = "\(dateString) \(selectedTime)"
        let appointmentDateTime = timeFormatter.date(from: combinedDateTimeString)
        
        // Create a unique appointment ID
        let appointmentId = UUID().uuidString
        
        // Get the patient ID from UserDefaults
        guard let patientId = UserDefaults.standard.string(forKey: "userId") else {
            errorMessage = "Patient ID not found"
            showingError = true
            isLoading = false
            return
        }
        
        // Create appointment data using the Appointment model structure
        let appointmentData: [String: Any] = [
            "id": appointmentId,
            "patId": patientId,
            "patName": patient.name,
            "docId": doctorId,
            "docName": doctor.name,
            "patientRecordsId": patientId,
            "date": dateString,
            "time": selectedTime,
            "appointmentDateTime": appointmentDateTime as Any,
            "status": AppointmentData.AppointmentStatus.scheduled.rawValue,
            "durationMinutes": appointmentDuration,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp(),
            "database": dbName,
            "userType": UserDefaults.standard.string(forKey: "userType") ?? "patient"
        ]
        
        // Save to Firestore
        Task {
            do {
                // First check if patient exists in Firestore
                let patientDoc = try await db.collection("\(dbName)_patients").document(patientId).getDocument()
                
                if !patientDoc.exists {
                    // Create patient document if it doesn't exist
                    try await db.collection("\(dbName)_patients").document(patientId).setData([
                        "id": patientId,
                        "name": patient.name,
                        "email": patient.email,
                        "createdAt": FieldValue.serverTimestamp(),
                        "database": dbName,
                        "userType": "patient"
                    ])
                }
                
                // Now save the appointment
                try await db.collection("\(dbName)_appointments").document(appointmentId).setData(appointmentData)
                
                await MainActor.run {
                    isLoading = false
                    showingConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to book appointment: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct DoctorInfoHeader: View {
    let doctor: DoctorProfile
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.medicareBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                Text(doctor.speciality)
                    .foregroundColor(.gray)
                if let gender = doctor.gender {
                    Text(gender)
                        .foregroundColor(.medicareDarkBlue)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
