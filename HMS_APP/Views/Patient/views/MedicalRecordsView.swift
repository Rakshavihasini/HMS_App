//
//  MedicalRecordsView.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//

import SwiftUI
import FirebaseFirestore

struct MedicalRecordsView: View {
    @EnvironmentObject var appointmentManager: AppointmentManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject var symptomCheckerViewModel = SymptomCheckerViewModel()
    @State private var patient: Patient?
    @State private var isLoading = true
    @State private var selectedAppointment: AppointmentData? = nil
    @State private var showRescheduleModal = false

    var currentAppointments: [AppointmentData] {
        appointmentManager.patientAppointments.filter {
            $0.status == .scheduled || $0.status == .inProgress || $0.status == .rescheduled
        }
    }
    
    var pastAppointments: [AppointmentData] {
        appointmentManager.patientAppointments.filter {
            $0.status == .completed || $0.status == .cancelled || $0.status == .noShow
        }
    }
    
    var body: some View {
        VStack {
            if isLoading || appointmentManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                List {
                    if !currentAppointments.isEmpty {
                        Section(header: SectionHeader("Current Appointments")) {
                            ForEach(currentAppointments) { appointment in
                                AppointmentRow(appointment: appointment)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        print("DEBUG: MedicalRecordsView - appointment tapped, ID: " + appointment.id)
                                        selectedAppointment = appointment
                                    }
                            }
                        }
                    }
                    
                    Section(header: SectionHeader("Past Appointments")) {
                        if pastAppointments.isEmpty {
                            Text("No past appointments")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(pastAppointments) { appointment in
                                AppointmentRow(appointment: appointment)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedAppointment = appointment
                                    }
                            }
                        }
                    }
                    
                    Section(header: SectionHeader("Medical Documents")) {
                        NavigationLink(destination: MedicalRecordsUploadView()) {
                            ListRow(title: "Upload & View Records", icon: "doc.text.fill")
                        }
                    }
                    
                    Section(header: SectionHeader("Medical History")) {
                        NavigationLink(destination: QuestionnaireView(viewModel: symptomCheckerViewModel)) {
                            ListRow(title: "Symptom Checker", icon: "cross.fill")
                        }
                    }
                }
            }
        }
        .navigationTitle("Medical Records")
        .task {
            await fetchPatientInfo()
            await appointmentManager.fetchAppointments()
        }
        .refreshable {
            await fetchPatientInfo()
            await appointmentManager.fetchAppointments()
        }
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentSheetContents(
                appointment: appointment,
                showRescheduleModal: $showRescheduleModal,
                appointmentManager: appointmentManager,
                onDismiss: { 
                    // No need to do anything here as the sheet is managed by the sheet(item:) modifier
                }
            )
            .onDisappear {
                if !showRescheduleModal {
                    // Only clear selection if not showing reschedule modal
                    selectedAppointment = nil
                }
            }
        }
        .sheet(isPresented: $showRescheduleModal) {
            if let appointment = selectedAppointment {
                AppointmentRescheduleView(appointment: appointment)
            } else {
                Text("No appointment selected for rescheduling")
            }
        }
    }
    
    private func fetchPatientInfo() async {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            isLoading = false
            return
        }
        let email = "user@gmail.com"
        do {
            let patientData = try await PatientFirestoreService.shared.getOrCreatePatient(
                userId: userId,
                name: "Patient",
                email: email
            )
            
            await MainActor.run {
                self.patient = patientData
                self.isLoading = false
            }
        } catch {
            print("Error fetching patient data: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct AppointmentRow: View {
    let appointment: AppointmentData
    
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
            return "No date"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: dateTime)
    }
    
    var formattedTime: String {
        guard let dateTime = appointment.appointmentDateTime else {
            return "No time"
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: dateTime)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appointment.doctorName)
                    .font(.headline)
                Spacer()
                if let status = appointment.status {
                    Text(status.rawValue)
                        .font(.caption)
                        .padding(5)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(5)
                }
            }
            
            if let notes = appointment.notes {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "calendar")
                Text("\(formattedDate) at \(formattedTime)")
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Reusable UI Components
struct SectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.medicareBlue)
    }
}

struct ListRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.medicareBlue)
                .frame(width: 30)
            Text(title)
        }
        .padding(.vertical, 5)
    }
}

