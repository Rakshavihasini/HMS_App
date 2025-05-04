//
//  PatientDashboard.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//

import SwiftUI
import FirebaseFirestore

struct PatientDashboardView: View {
    @EnvironmentObject var appointmentManager: AppointmentManager
    @EnvironmentObject var authManager: AuthManager
    @State private var patient: Patient?
    @State private var isLoading = true

    var currentAppointments: [AppointmentData] {
        appointmentManager.patientAppointments.filter {
            $0.status == .scheduled || $0.status == .inProgress || $0.status == .rescheduled
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    DashboardHeaderView(patientName: patient?.name ?? "Patient")
                    QuickActionsView()

                    if appointmentManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else if currentAppointments.isEmpty {
                        NoAppointmentsView()
                    } else {
                        CurrentAppointmentsSection(appointments: currentAppointments)
                    }

                    LatestReportsView()
                    RemindersView()
                }
            }
            .padding(.vertical)
        }
        .navigationBarHidden(true)
        .task {
            await fetchPatientInfo()
            await appointmentManager.fetchAppointments()
        }
        .refreshable {
            await fetchPatientInfo()
            await appointmentManager.fetchAppointments()
        }
        .primaryBackground()
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
                email: email,
                gender: "Male"
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

// MARK: - Dashboard Header
struct DashboardHeaderView: View {
    let patientName: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back,")
                    .font(.title3)
                    .foregroundColor(.gray)
                Text(patientName)
                    .font(.title)
                    .bold()
                    .adaptiveTextColor()
            }
            Spacer()
            
            NavigationLink {
                PatientProfileView()
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.medicareBlue)
                    .padding(5)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - No Appointments View
struct NoAppointmentsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("No Upcoming Appointments")
                .font(.headline)
                .padding(.top)
            
            Text("Book an appointment with a doctor to get started")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: DoctorsView()) {
                Text("Find a Doctor")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.medicareBlue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .themedCard()
        .padding(.horizontal)
    }
}

// MARK: - Quick Actions
struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 15) {
                NavigationLink(destination: DoctorsView()) {
                    DashboardActionButton(title: "Book Appointment", icon: "calendar.badge.plus")
                }

                NavigationLink(destination: QuestionaireContentView()) {
                    DashboardActionButton(title: "Find Doctor", icon: "stethoscope")
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DashboardActionButton: View {
    let title: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .background(Color.medicareBlue)
                .clipShape(Circle())

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(colorScheme == .dark ? Theme.dark.card : Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: colorScheme == .dark ? Theme.dark.shadow : .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Appointments
struct CurrentAppointmentsSection: View {
    let appointments: [AppointmentData]
    @EnvironmentObject var appointmentManager: AppointmentManager
    @State private var selectedAppointment: AppointmentData? = nil
    @State private var showRescheduleModal = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader(title: "Current Appointments", destination: MedicalRecordsView())

            ForEach(appointments.prefix(2)) { appointment in
                AppointmentCard(appointment: appointment)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAppointment = appointment
                        print("DEBUG: Appointment tapped - ID: \(appointment.id)")
                        print("DEBUG: Doctor: \(appointment.doctorName), DateTime: \(appointment.appointmentDateTime?.description ?? "Not scheduled")")
                        print("DEBUG: Notes: \(appointment.notes ?? "No notes"), Status: \(appointment.status?.rawValue ?? "Unknown")")
                    }
            }
        }
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentSheetContents(
                appointment: appointment,
                showRescheduleModal: $showRescheduleModal,
                appointmentManager: appointmentManager,
                onDismiss: { 
                    // Will be handled by onDisappear
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
}

// MARK: - Reports
struct LatestReportsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionHeader(title: "Latest Reports", destination: MedicalRecordsView())

            ReportCard(title: "Blood Test", date: "May 15, 2023", status: "Normal")
            ReportCard(title: "X-Ray Chest", date: "April 22, 2023", status: "Clear")
        }
    }
}

struct ReportCard: View {
    let title: String
    let date: String
    let status: String

    var statusColor: Color {
        status == "Normal" || status == "Clear" ? .medicareGreen : .medicareRed
    }

    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.medicareBlue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(status)
                .font(.subheadline)
                .foregroundColor(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

// MARK: - Reminders
struct RemindersView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.headline)
                .padding(.horizontal)

            ReminderCard(title: "Take Metformin", time: "8:00 AM", isCompleted: true)
            ReminderCard(title: "Blood Pressure Check", time: "7:00 PM", isCompleted: false)
        }
    }
}

struct ReminderCard: View {
    let title: String
    let time: String
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .medicareGreen : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isCompleted ? .gray : .primary)
                    .strikethrough(isCompleted)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

// MARK: - Reusable Section Header
struct DashboardSectionHeader<Destination: View>: View {
    let title: String
    let destination: Destination

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()

            NavigationLink(destination: destination) {
                Text("View All")
                    .font(.subheadline)
                    .foregroundColor(.medicareBlue)
            }
        }
        .padding(.horizontal)
    }
}
