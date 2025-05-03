//
//  ConsultationDetailView.swift
//  HMS_APP
//
//  Created by Rudra Pruthi on 02/05/25.
//

import SwiftUI

struct DoctorConsultationDetailView: View {
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
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.patientName)
                            .font(.title2)
                            .bold()
                            .foregroundColor(theme.text)
                        
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
                                    Button("In Progress") {
                                        updateStatus(.inProgress)
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
            .navigationBarTitleDisplayMode(.inline)
            .background(theme.background)
            .ignoresSafeArea(.keyboard)
        }
    }
    
    // Function to update appointment status
    private func updateStatus(_ newStatus: AppointmentData.AppointmentStatus) {
        isUpdatingStatus = true
        Task {
            let success = await appointmentViewModel.updateAppointmentStatus(
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

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value ?? "")
                .font(.subheadline)
            
            Spacer()
        }
    }
} 
