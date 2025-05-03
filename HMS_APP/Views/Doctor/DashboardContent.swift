//
//  DashboardContent.swift
//  HMS_APP
//
//  Created by Rudra Pruthi on 02/05/25.
//


import SwiftUI

// MARK: - Dashboard Main Content
struct DashboardContent: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var doctorManager: DoctorManager
    @StateObject private var appointmentViewModel = Appointment()
    @Binding var selectedTab: String
    @State private var showingConsultationDetail = false // Add state for navigation
    @State private var selectedAppointmentForDetail: AppointmentData? = nil // Add state for selected appointment
    @State private var showingRescheduleView = false // Add state for reschedule navigation
    @State private var selectedAppointmentForReschedule: AppointmentData? = nil // Add state for selected appointment reschedule

    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }

    var body: some View {
        func greetingMessage() -> String {
                let currentHour = Calendar.current.component(.hour, from: Date())
                    if currentHour >= 5 && currentHour < 12 {
                        return "Good Morning"
                    } else if currentHour >= 12 && currentHour < 17 {
                        return "Good Afternoon"
                    } else {
                        return "Good Evening"
                    }
                }
        
        return VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack{
                        Text("\(greetingMessage())")
                            .font(.title)
                            .bold()
                            .foregroundColor(theme.text)
                        Spacer()
                        NavigationLink(destination: DoctorProfileView().environmentObject(doctorManager)) {
                            Image(systemName: "person.circle")
                                .font(.title)
                                .foregroundColor(theme.primary)
                        }
                    }
                    
                    if let userInfo = doctorManager.currentUserInfo,
                       let name = userInfo["name"] as? String {
                        Text("Dr. \(name)")
                            .foregroundColor(.gray)
                    } else {
                        Text("Doctor")
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                // Removed NavigationLink to profile since it's in the toolbar
            }
            .padding(.horizontal)
//            .padding(.top, 20)

            HStack {
                Button(action: {
                    selectedTab = "Upcoming"
                }) {
                    Text("Upcoming")
                        .foregroundColor(selectedTab == "Upcoming" ? .white : theme.primary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .background(selectedTab == "Upcoming" ? theme.primary : Color.clear)
                        .cornerRadius(25)
                }
                Button(action: {
                    selectedTab = "Past"
                   
                }) {
                    Text("Past")
                        .foregroundColor(selectedTab == "Past" ? .white : theme.primary)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .background(selectedTab == "Past" ? theme.primary : Color.clear)
                        .cornerRadius(25)
                }
            }
            .background(theme.card)
            .clipShape(Capsule())
            .frame(height: 45)
            .padding(.horizontal)

            // See All Button only for "Past"
            if selectedTab == "Past" {
                HStack {
                    Spacer()
                    NavigationLink(destination: PastAppointmentsCalendarView()) {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundColor(theme.primary)
                            .padding(.trailing)
                    }
                }
            }

            if appointmentViewModel.isLoading {
                Spacer()
                ProgressView("Loading appointments...")
                    .padding()
                Spacer()
            } else if (selectedTab == "Upcoming" && appointmentViewModel.upcomingAppointments.isEmpty) ||
                      (selectedTab == "Past" && appointmentViewModel.pastAppointments.isEmpty) {
                Spacer()
                VStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(selectedTab == "Upcoming" ? "No upcoming appointments" : "No past appointments")
                        .font(.headline)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 50)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        let appointments = selectedTab == "Upcoming" ?
                            appointmentViewModel.upcomingAppointments : appointmentViewModel.pastAppointments

                        ForEach(appointments) { appointment in
                            ConsultationCard(
                                appointment: appointment,
                                onReschedule: { // Pass the closure to handle reschedule tap
                                    selectedAppointmentForReschedule = appointment
                                    showingRescheduleView = true
                                },
                                onStartConsult: { // Pass the closure to handle tap
                                    selectedAppointmentForDetail = appointment
                                    showingConsultationDetail = true
                                }
                            )
                        }
                    }
                    .padding()
                }
                // NavigationDestination for Consultation Detail
                .navigationDestination(isPresented: $showingConsultationDetail) {
                     if let appointment = selectedAppointmentForDetail {
                         DoctorConsultationDetailView(appointment: appointment)
                     } else {
                         Text("Error: No appointment selected.")
                     }
                 }
                 // Add NavigationDestination for Reschedule View
                 .navigationDestination(isPresented: $showingRescheduleView) {
                      if let appointment = selectedAppointmentForReschedule {
                          RescheduleView(appointment: appointment) // Navigate to RescheduleView
                      } else {
                          Text("Error: No appointment selected for reschedule.")
                      }
                  }
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .background(theme.background)
        .task {
            if let userInfo = doctorManager.currentUserInfo, let doctorId = userInfo["id"] as? String {
                await appointmentViewModel.fetchAppointments(for: doctorId)
            }
        }
    }
}

// MARK: - Consultation Detail View
struct ConsultationDoctorDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var doctorManager: DoctorManager
    let appointment: AppointmentData
    @State private var prescription: String = ""
    @State private var notes: String = ""
    @State private var selectedTab: String = "CONSULT"
    @State private var isUpdatingStatus: Bool = false
    @StateObject private var appointmentViewModel = Appointment()
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 28) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        if !appointment.patientName.isEmpty {
                            Text(appointment.patientName)
                                .font(.title2)
                                .bold()
                                .foregroundColor(theme.text)
                        } else {
                            Text("Patient ID: \(appointment.patientId)")
                                .font(.title2)
                                .bold()
                                .foregroundColor(theme.text)
                        }
                        
                        Text("Dr. \(appointment.doctorName)")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    PatientAvatar(name: appointment.patientName)
                        .frame(width: 48, height: 48)
                }
                .padding(.horizontal)
                
                // Toggle Tabs
                HStack(spacing: 0) {
                    SegmentButton(title: "Consult", isSelected: selectedTab == "CONSULT", theme: theme) {
                        selectedTab = "CONSULT"
                    }
                    SegmentButton(title: "Patient History", isSelected: selectedTab == "PATIENT HISTORY", theme: theme) {
                        selectedTab = "PATIENT HISTORY"
                        prescription = ""
                        notes = ""
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                if selectedTab == "CONSULT" {
                    // Appointment Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("APPOINTMENT DETAILS:")
                            .font(.headline)
                            .foregroundColor(theme.text)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Date", value: appointment.date ?? "")
                            InfoRow(label: "Time", value: appointment.time)
                            InfoRow(label: "Reason", value: appointment.reason ?? "General Checkup")
                            HStack {
                                Text("Status")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondary)
                                    .frame(width: 100, alignment: .leading)
                                
                                Menu {
                                    Button("Scheduled") {
                                        updateStatus(.scheduled)
                                    }
                                    Button("Confirmed") {
                                        updateStatus(.scheduled)
                                    }
                                    Button("Completed") {
                                        updateStatus(.completed)
                                    }
                                    Button("Cancelled") {
                                        updateStatus(.cancelled)
                                    }
                                } label: {
                                    HStack {
                                        if isUpdatingStatus {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                                .padding(.trailing, 4)
                                        }
                                        Text(appointment.status?.rawValue ?? "SCHEDULED")
                                            .font(.subheadline)
                                            .foregroundColor(
                                                getStatusColor(status: appointment.status?.rawValue ?? "SCHEDULED")
                                            )
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                    }
                                }
                                .disabled(isUpdatingStatus)
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color(hex: "#333333") : Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Prescription
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRESCRIPTION:")
                            .font(.headline)
                            .foregroundColor(theme.text)
                        
                        TextEditor(text: $prescription)
                            .frame(height: 120)
                            .padding(10)
                            .background(colorScheme == .dark ? Color(hex: "#333333") : Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES:")
                            .font(.headline)
                            .foregroundColor(theme.text)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(10)
                            .background(colorScheme == .dark ? Color(hex: "#333333") : Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    // Patient History Placeholder
                    VStack {
                        Spacer()
                        Text("No patient history data to show.")
                            .font(.body)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
                
                Spacer()
                
                // Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        print("💾 Draft Saved")
                    }) {
                        HStack {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text("Save Draft")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.primary, lineWidth: 1.5)
                        )
                        .foregroundColor(theme.primary)
                        .shadow(color: theme.shadow, radius: 4, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        // Mark as completed
                        updateStatus(.completed)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: theme.shadow, radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top)
            .navigationTitle("Consultation")
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .background(theme.background)
            .ignoresSafeArea(.keyboard)
        }
    }
    
    // Function to update appointment status
    private func updateStatus(_ newStatus: AppointmentData.AppointmentStatus) {
        isUpdatingStatus = true
        Task {
            await appointmentViewModel.updateAppointmentStatus(
                appointmentId: appointment.id, 
                newStatus: newStatus
            )
            await MainActor.run {
                isUpdatingStatus = false
            }
        }
    }
    
    // Get color for status
    private func getStatusColor(status: String) -> Color {
        switch status.lowercased() {
        case "scheduled", "confirmed", "upcoming":
            return .green
        case "cancelled":
            return .red
        case "completed":
            return .blue
        default:
            return .gray
        }
    }
}


// MARK: - Segment Button
struct SegmentButton: View {
    var title: String
    var isSelected: Bool
    var theme: Theme
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? theme.primary : theme.card)
                .foregroundColor(isSelected ? .white : theme.primary)
                .font(.headline)
        }
        .background(isSelected ? theme.primary : theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
} 
