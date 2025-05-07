//
//  AdminPaymentView.swift
//  HMS_APP
//
//  Created by rjk on 06/05/25.
//


import SwiftUI
import FirebaseFirestore

struct AdminAppointmentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var appointments: [AppointmentData] = []
    @State private var isLoading = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedAppointment: AppointmentData? = nil
    @State private var showingConfirmationDialog = false
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    var pendingPaymentAppointments: [AppointmentData] {
        appointments.filter { appointment in
            // We need to fetch the appointments with pending payment status and WAITING status
            // This will ensure we only show appointments that need payment confirmation
            return appointment.status == .noShow
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                } else if pendingPaymentAppointments.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("No Pending Payments")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("All appointment payments have been confirmed")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List {
                        Section(header: Text("Appointments Pending Confirmation")) {
                            ForEach(pendingPaymentAppointments, id: \.id) { appointment in
                                AppointmentPaymentRow(appointment: appointment)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedAppointment = appointment
                                        showingConfirmationDialog = true
                                    }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .navigationTitle("Payment Confirmation")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchAppointments()
            }
            .refreshable {
                fetchAppointments()
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Notification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .confirmationDialog(
                "Confirm Appointment",
                isPresented: $showingConfirmationDialog,
                titleVisibility: .visible
            ) {
                Button("Confirm Appointment") {
                    if let appointment = selectedAppointment {
                        confirmPayment(for: appointment)
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    selectedAppointment = nil
                }
            } message: {
                if let appointment = selectedAppointment {
                    Text("Confirm appointment for \(appointment.patientName) with \(appointment.doctorName) on \(formattedDate(appointment))")
                } else {
                    Text("Select an appointment")
                }
            }
        }
    }
    
    private func fetchAppointments() {
        isLoading = true
        
        // Debug the query parameters
        print("Fetching appointments with status: \(AppointmentData.AppointmentStatus.noShow.rawValue)")
        
        // Print the raw value to ensure we're using the correct string
        print("noShow status raw value: \(AppointmentData.AppointmentStatus.noShow.rawValue)")
        
        // Query for appointments with pending payment and WAITING status
        db.collection("\(dbName)_appointments")
            .whereField("paymentStatus", isEqualTo: "pending")
            .whereField("status", isEqualTo: "WAITING")
            .getDocuments { snapshot, error in
                if let error = error {
                    alertMessage = "Error fetching appointments: \(error.localizedDescription)"
                    showingAlert = true
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    isLoading = false
                    return
                }
                
                print("Found \(documents.count) appointments")
                
                self.appointments = documents.compactMap { document -> AppointmentData? in
                    let data = document.data()
                    print("Processing document: \(document.documentID), status: \(data["status"] as? String ?? "unknown")")
                    
                    // Parse date and time
                    var appointmentDateTime: Date? = nil
                    if let timestamp = data["appointmentDateTime"] as? Timestamp {
                        appointmentDateTime = timestamp.dateValue()
                    }
                    
                    // Parse status
                    var status: AppointmentData.AppointmentStatus? = nil
                    if let statusString = data["status"] as? String,
                       let appointmentStatus = AppointmentData.AppointmentStatus(rawValue: statusString) {
                        status = appointmentStatus
                    }
                    
                    return AppointmentData(
                        id: document.documentID,
                        patientId: data["patId"] as? String ?? "",
                        patientName: data["patName"] as? String ?? "",
                        doctorId: data["docId"] as? String ?? "",
                        doctorName: data["docName"] as? String ?? "",
                        patientRecordsId: data["patientRecordsId"] as? String ?? "",
                        appointmentDateTime: appointmentDateTime,
                        status: status,
                        durationMinutes: data["durationMinutes"] as? Int,
                        notes: data["notes"] as? String,
                        date: data["date"] as? String,
                        reason: data["reason"] as? String
                    )
                }
                
                isLoading = false
            }
    }
    
    private func confirmPayment(for appointment: AppointmentData) {
        isLoading = true
        
        db.collection("\(dbName)_appointments").document(appointment.id).updateData([
            "paymentStatus": "completed",
            "status": AppointmentData.AppointmentStatus.scheduled.rawValue,
            "adminConfirmed": true
        ]) { error in
            if let error = error {
                alertMessage = "Error confirming payment: \(error.localizedDescription)"
                showingAlert = true
                isLoading = false
                return
            }
            
            // Payment confirmed successfully
            alertMessage = "Payment confirmed successfully and appointment has been scheduled"
            showingAlert = true
            selectedAppointment = nil
            
            // Refresh the appointments list
            fetchAppointments()
        }
    }
    
    private func formattedDate(_ appointment: AppointmentData) -> String {
        if let dateTime = appointment.appointmentDateTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: dateTime)
        } else if let dateString = appointment.date {
            return dateString
        }
        return "Unknown date"
    }
}

struct AppointmentPaymentRow: View {
    let appointment: AppointmentData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appointment.patientName)
                    .font(.headline)
                Spacer()
                Text("Payment Pending")
                    .font(.caption)
                    .padding(5)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(5)
            }
            
            Text("Doctor: \(appointment.doctorName)")
                .font(.subheadline)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                if let dateTime = appointment.appointmentDateTime {
                    let formatter = DateFormatter()
                    Text(formatter.string(from: dateTime))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if let dateString = appointment.date {
                    Text(dateString)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                if !appointment.time.isEmpty {
                    Text(appointment.time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if let dateTime = appointment.appointmentDateTime {
                    let formatter = DateFormatter()
                    Text(formatter.string(from: dateTime))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("Time not set")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            if let reason = appointment.reason, !reason.isEmpty {
                Text("Reason: \(reason)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AdminAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AdminAppointmentView()
    }
}
