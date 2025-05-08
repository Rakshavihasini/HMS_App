//
//  PatientDetailView.swift
//  HMS_Admin
//
//  Created by rjk on 24/04/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

// Appointment model
struct Appointment1: Identifiable {
    let id = UUID()
    let type: String
    let date: String
    let time: String
    let status: String
    let progress: Float // 0.0 to 1.0
}

struct PatientDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let patient: Patient
    
    // Payment data
    @State private var totalBill: Int = 0
    @State private var paid: Int = 0
    @State private var pending: Int = 0
    
    // Use AppointmentManager for appointments
    @ObservedObject var appointmentManager: AppointmentManager
    @State private var showingCalendar = false
    
    // Alert states
    @State private var showingConfirmationAlert = false
    @State private var selectedAppointment: AppointmentData? = nil
    
    private func fetchPaymentData() {
        let db = Firestore.firestore()
        db.collection("hms4_transactions")
            .whereField("patientId", isEqualTo: patient.id)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching payments: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                var totalAmount = 0
                var paidAmount = 0
                var pendingAmount = 0
                
                for doc in documents {
                    let data = doc.data()
                    if let amount = data["amount"] as? Int,
                       let paymentStatus = data["paymentStatus"] as? String {
                        totalAmount += amount
                        if paymentStatus == "completed" {
                            paidAmount += amount
                        } else if paymentStatus == "pending" {
                            pendingAmount += amount
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.totalBill = totalAmount
                    self.paid = paidAmount
                    self.pending = pendingAmount
                }
            }
    }
    
    // Function to handle payment confirmation and status update
    private func confirmPayment(for appointment: AppointmentData) {
        let appointmentId = appointment.id
        
        // Find the transaction for this appointment
        let db = Firestore.firestore()
        db.collection("hms4_transactions")
            .whereField("appointmentId", isEqualTo: appointmentId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching transaction: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents, let transactionDoc = documents.first else {
                    print("Transaction not found")
                    return
                }
                
                let transactionId = transactionDoc.documentID
                let data = transactionDoc.data()
                let amount = data["amount"] as? Int ?? 0
                
                // Create a batch write to update both collections atomically
                let batch = db.batch()
                
                // Update transaction status to completed
                let transactionRef = db.collection("hms4_transactions").document(transactionId)
                batch.updateData(["paymentStatus": "completed"], forDocument: transactionRef)
                
                // Update appointment status to scheduled
                let appointmentRef = db.collection("hms4_appointments").document(appointmentId)
                batch.updateData(["status": "SCHEDULED"], forDocument: appointmentRef)
                batch.updateData(["paymentStatus": "completed"], forDocument: appointmentRef)
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("Error updating documents: \(error)")
                        return
                    }
                    
                    // Update local payment data
                    DispatchQueue.main.async {
                        self.pending -= amount
                        self.paid += amount
                        
                        // Refresh appointments
                        Task {
                            await self.appointmentManager.fetchAppointments(for: self.patient.id)
                        }
                    }
                }
            }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background color for the entire view
            (colorScheme == .dark ? Color(UIColor.systemGray6) : Color(.systemGray6))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Blue header with gradient extending into safe area
                ZStack(alignment: .bottom) {
                    // Background gradient for both light and dark modes
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .dark ? Color(red: 0.15, green: 0.4, blue: 0.8) : Color(red: 0.2, green: 0.5, blue: 0.9),
                            colorScheme == .dark ? Color(red: 0.24, green: 0.46, blue: 0.78) : Color(red: 0.29, green: 0.56, blue: 0.88)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.top) // Extend blue into top safe area
                    
                    VStack(spacing: 0) {
                        // Back button and title
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .imageScale(.large)
                                    .padding(8)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Text("Patient Details")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                // Action for menu
                            }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.white)
                                    .imageScale(.large)
                                    .padding(8)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // Patient info section
                        VStack(spacing: 16) {
                            HStack(alignment: .center, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white)
                                        .frame(width: 30, height: 30)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(patient.name)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
//                                    if let phoneNumber = patient.phoneNumber {
//                                        HStack {
//                                            Image(systemName: "phone.fill")
//                                                .foregroundColor(.white.opacity(0.8))
//                                                .font(.footnote)
//                                            Text(phoneNumber)
//                                                .foregroundColor(.white)
//                                                .font(.system(size: 14))
//                                        }
//                                        .padding(.top, 6)
//                                    }
                                    
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.footnote)
                                        Text("\(patient.age != nil ? "\(patient.age!), " : "")\(patient.gender ?? "Not specified")")
                                            .foregroundColor(.white)
                                            .font(.system(size: 14))
                                    }
                                    .padding(.top, 2)
                                }
                                
                                Spacer()
                            }
                            
                            // Financial summary
                            HStack(spacing: 0) {
                                VStack(spacing: 6) {
                                    Text("₹\(totalBill)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Total Bill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                              
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                    .frame(height: 34)
                              
                                VStack(spacing: 6) {
                                    Text("₹\(paid)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Paid")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                              
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                    .frame(height: 34)
                              
                                VStack(spacing: 6) {
                                    Text("₹\(pending)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Pending")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .background(
                                Color.white.opacity(0.05)
                                    .blur(radius: 10)
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 18)
                    }
                }
                .frame(height: 200)
                                          
                                        
                // Appointments header
                HStack {
                    Text("Appointments")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.3, blue: 0.6))
                    
                    Spacer()
                    
                    Button(action: {
                        showingCalendar = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text("Calendar")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color(red: 0.2, green: 0.5, blue: 0.9)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Content area
                if appointmentManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                } else if let error = appointmentManager.error {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if appointmentManager.patientAppointments.isEmpty {
                                Text("No appointments found")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(appointmentManager.patientAppointments) { appointment in
                                    AppointmentCardView(appointment: appointment, colorScheme: colorScheme)
                                        .padding(.horizontal, 20)
                                        .onTapGesture {
                                            // Check if appointment status is "WAITING" (noShow)
                                            if appointment.status == .noShow {
                                                selectedAppointment = appointment
                                                showingConfirmationAlert = true
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.bottom, 20)
                    }
                    .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
                }
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            .onAppear {
                // Only fetch payment data, the appointment manager should be passed in with data
                fetchPaymentData()
            }
        }
        .alert("Confirm Payment", isPresented: $showingConfirmationAlert) {
            Button("Confirm") {
                if let appointment = selectedAppointment {
                    confirmPayment(for: appointment)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you want to confirm payment for this appointment? This will change the status from Waiting to Scheduled.")
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCalendar) {
            AppointmentCalendarView(appointments: appointmentManager.patientAppointments)
        }
    }
}

// Appointment card view
struct AppointmentCardView: View {
    let appointment: AppointmentData
    let colorScheme: ColorScheme
    
    private var currentStatus: AppointmentData.AppointmentStatus {
        // Use the actual status from the database instead of auto-marking past appointments as completed
        return appointment.status ?? .scheduled
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color(UIColor.systemGray4) : Color(red: 0.95, green: 0.97, blue: 1.0),
                                colorScheme == .dark ? Color(UIColor.systemGray5) : Color(red: 0.9, green: 0.95, blue: 1.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: getIconName(for: appointment.notes ?? ""))
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.doctorName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(formatDate(appointment.appointmentDateTime))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(formatTime(appointment.appointmentDateTime))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Updated status badge
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor(for: currentStatus))
                    .frame(width: 6, height: 6)
                
                Text(currentStatus.rawValue.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(statusColor(for: currentStatus))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(statusColor(for: currentStatus).opacity(0.15))
            )
            .animation(.easeInOut(duration: 0.2), value: currentStatus)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray5) : Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func statusColor(for status: AppointmentData.AppointmentStatus) -> Color {
        switch status {
        case .completed:
            return Color.green
        case .scheduled:
            return Color.blue
        case .cancelled:
            return Color.red
        case .inProgress:
            return Color.orange
        case .noShow:
            return Color.gray
        case .rescheduled:
            return Color.purple
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func getIconName(for reason: String) -> String {
        let lowercaseReason = reason.lowercased()
        switch lowercaseReason {
        case let r where r.contains("checkup"):
            return "stethoscope"
        case let r where r.contains("dental"):
            return "tooth"
        case let r where r.contains("physical"):
            return "heart.text.square"
        default:
            return "cross.case"
        }
    }
}

struct AppointmentCalendarView: View {
    let appointments: [AppointmentData]
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate = Date()
    
    private var appointmentsByDate: [Date: [AppointmentData]] {
        Dictionary(grouping: appointments) { appointment in
            Calendar.current.startOfDay(for: appointment.appointmentDateTime ?? Date())
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.blue)
                .padding()
                
                Divider()
                
                List {
                    let selectedDayStart = Calendar.current.startOfDay(for: selectedDate)
                    if let dayAppointments = appointmentsByDate[selectedDayStart] {
                        ForEach(dayAppointments) { appointment in
                            AppointmentRow(appointment: appointment)
                        }
                    } else {
                        Text("No appointments on this date")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
            .navigationTitle("Appointments Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AppointmentRow1: View {
    let appointment: AppointmentData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appointment.doctorName)
                .font(.headline)
            
            if let dateTime = appointment.appointmentDateTime {
                Text(formatTime(dateTime))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text(appointment.notes ?? "No reason provided")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                StatusBadge1(status: appointment.status, appointmentDate: appointment.appointmentDateTime)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatusBadge1: View {
    let status: AppointmentData.AppointmentStatus?
    let appointmentDate: Date?
    
    private var currentStatus: AppointmentData.AppointmentStatus {
        if let date = appointmentDate,
           date < Date() {
            return .completed
        }
        return status ?? .scheduled
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(for: currentStatus))
                .frame(width: 6, height: 6)
            
            Text(currentStatus.rawValue.uppercased())
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(statusColor(for: currentStatus))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(statusColor(for: currentStatus).opacity(0.15))
        )
        .animation(.easeInOut(duration: 0.2), value: currentStatus)
    }
    
    private func statusColor(for status: AppointmentData.AppointmentStatus) -> Color {
        switch status {
        case .completed:
            return Color.green
        case .scheduled:
            return Color.blue
        case .cancelled:
            return Color.red
        case .inProgress:
            return Color.orange
        case .noShow:
            return Color.gray
        case .rescheduled:
            return Color.purple
        }
    }
}



