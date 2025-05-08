//
//  PaymentConfirmationView.swift
//  HMS_APP
//
//  Created by rjk on 06/05/25.
//
import SwiftUI
import FirebaseFirestore

// Payment Confirmation View
struct PaymentConfirmationView: View {
    let doctor: DoctorProfile
    let date: Date
    let time: String
    let reason: String
    let consultationFee: Int
    let onConfirm: () -> Void  // Keep for counter payments
    let onCancel: () -> Void
    // Add a new closure for online payments
    var onConfirmOnline: (() -> Void)? = nil
    
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    @StateObject private var router = Router<ViewPath>()
    @State private var isLoading = false
    
    enum PaymentMethod {
        case counter, online
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Function to create appointment in Firebase and navigate to payment
    private func createAppointmentAndNavigateToPayment() {
        // Set loading state
        isLoading = true
        
        // Create a new appointment ID
        let appointmentId = UUID().uuidString
        // Store the appointment ID in UserDefaults for the payment gateway to use
        UserDefaults.standard.set(appointmentId, forKey: "currentAppointmentId")
        
        // Get patient ID from UserDefaults
        guard let patientId = UserDefaults.standard.string(forKey: "userId") else {
            print("Error: Patient ID not found")
            isLoading = false
            return
        }
        
        // Format date for Firebase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Format appointment time
        let startTime = time.components(separatedBy: " - ")[0]
        
        // Create combined date/time
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd h:mma"
        let combinedDateTimeString = "\(dateString) \(startTime)"
        let appointmentDateTime = timeFormatter.date(from: combinedDateTimeString.lowercased())
        
        // Save payment method to UserDefaults
        UserDefaults.standard.set("online", forKey: "selectedPaymentMethod")
        
        // Create appointment data
        let appointmentData: [String: Any] = [
            "id": appointmentId,
            "patId": patientId,
            "patName": UserDefaults.standard.string(forKey: "userName") ?? "Patient",
            "docId": doctor.id ?? "",
            "docName": doctor.name,
            "patientRecordsId": patientId,
            "date": dateString,
            "time": startTime,
            "appointmentDateTime": appointmentDateTime as Any,
            "status": "SCHEDULED", // For online payments, set status to scheduled
            "paymentStatus": "pending", // Will be updated to completed after payment
            "durationMinutes": 30,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp(),
            "database": "hms4",
            "userType": UserDefaults.standard.string(forKey: "userType") ?? "patient",
            "consultationFee": consultationFee
        ]
        
        // Create transaction data
        let transactionId = UUID().uuidString
        let transactionData: [String: Any] = [
            "id": transactionId,
            "patientId": patientId,
            "doctorId": doctor.id ?? "",
            "amount": consultationFee,
            "paymentMethod": "online",
            "paymentStatus": "pending", // Will be updated to completed after payment
            "appointmentId": appointmentId,
            "appointmentDate": dateString,
            "transactionDate": FieldValue.serverTimestamp(),
            "type": "consultation_fee"
        ]
        
        let db = Firestore.firestore()
        
        // Store appointment and transaction data in Firebase
        Task {
            do {
                // Store appointment data
                try await db.collection("hms4_appointments").document(appointmentId).setData(appointmentData)
                print("Appointment successfully added to Firebase with ID: \(appointmentId)")
                
                // Store transaction data
                try await db.collection("hms4_transactions").document(transactionId).setData(transactionData)
                print("Transaction successfully added to Firebase with ID: \(transactionId)")
                
                // After successful creation, navigate to payment gateway
                await MainActor.run {
                    // Navigate to payment gateway
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Navigate to payment gateway
                        withAnimation {
                            self.router.path.append(ViewPath.payment)
                            print("Navigating to payment gateway: \(self.router.path)")
                        }
                        
                        // Reset loading state
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    print("Error creating appointment: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header section
                    paymentHeaderView
                    
                    // Appointment Summary
                    VStack(spacing: 20) {
                        // Doctor Info
                        doctorInfoView
                        
                        Divider()
                        
                        // Appointment Details
                        appointmentDetailsView
                        
                        Divider()
                        
                        // Payment Details
                        paymentDetailsView
                        
                        // Payment Options
                        paymentOptionsView
                        
                        // Buttons
                        actionButtonsView
                    }
                    .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ViewPath.self) { path in
                switch path {
                case .payment:
                    PaymentGatewayHelper(consultationFee: consultationFee)
                        .environmentObject(router)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Creating appointment...")
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
        .environmentObject(router)
    }
    
    // MARK: - Component Views
    
    private var paymentHeaderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 40))
                .foregroundColor(.medicareBlue)
                .padding(.top, 20)
            
            Text("Payment Information")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please review your appointment details and payment information")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
    }
    
    private var doctorInfoView: some View {
        HStack(spacing: 15) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.medicareBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                    .font(.headline)
                Text(doctor.speciality)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private var appointmentDetailsView: some View {
        VStack(spacing: 12) {
            DoctorDetailRow(title: "Date", value: formattedDate(date))
            DoctorDetailRow(title: "Time", value: time)
            DoctorDetailRow(title: "Reason", value: reason)
        }
        .padding(.horizontal)
    }
    
    private var paymentDetailsView: some View {
        VStack(spacing: 12) {
            DoctorDetailRow(title: "Consultation Fee", value: "₹\(consultationFee)")
            
            HStack {
                Text("Total Amount")
                    .font(.headline)
                Spacer()
                Text("₹\(consultationFee)")
                    .font(.headline)
                    .foregroundColor(.medicareBlue)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
    }
    
    private var paymentOptionsView: some View {
        VStack(spacing: 16) {
            Text("Select Payment Method")
                .font(.headline)
                .foregroundColor(.medicareBlue)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                payAtCounterButton
                payOnlineButton
            }
            
            paymentNoteView
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var payAtCounterButton: some View {
        Button(action: {
            selectedPaymentMethod = .counter
        }) {
            VStack(spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 28))
                Text("Pay at Counter")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPaymentMethod == .counter ?
                          Color.medicareBlue.opacity(0.2) :
                            (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPaymentMethod == .counter ?
                                    Color.medicareBlue : Color.gray.opacity(0.3),
                                    lineWidth: selectedPaymentMethod == .counter ? 2 : 1)
                    )
            )
            .foregroundColor(selectedPaymentMethod == .counter ?
                .medicareBlue : .primary)
        }
    }
    
    private var payOnlineButton: some View {
        Button(action: {
            selectedPaymentMethod = .online
        }) {
            VStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 28))
                Text("Pay Online")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPaymentMethod == .online ?
                          Color.medicareBlue.opacity(0.2) :
                            (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPaymentMethod == .online ?
                                    Color.medicareBlue : Color.gray.opacity(0.3),
                                    lineWidth: selectedPaymentMethod == .online ? 2 : 1)
                    )
            )
            .foregroundColor(selectedPaymentMethod == .online ?
                .medicareBlue : .primary)
        }
    }
    
    private var paymentNoteView: some View {
        Group {
            if selectedPaymentMethod == .counter {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.medicareBlue)
                    Text("Please pay at the hospital reception before your appointment")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .padding(.top, 8)
            } else if selectedPaymentMethod == .online {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.medicareBlue)
                    Text("Pay online by razorpay gateway")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // Add alert state
    @State private var showPaymentAlert = false
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Save payment method to UserDefaults
                if let method = selectedPaymentMethod {
                    let methodString = method == .counter ? "counter" : "online"
                    UserDefaults.standard.set(methodString, forKey: "selectedPaymentMethod")
                    
                    // Handle different payment methods
                    if method == .counter {
                        // Show alert for counter payment
                        showPaymentAlert = true
                    } else if method == .online {
                        // Use the dedicated online payment flow
                        if let onConfirmOnline = onConfirmOnline {
                            // Use the provided closure if available
                            onConfirmOnline()
                        } else {
                            // Use the default implementation
                            createAppointmentAndNavigateToPayment()
                        }
                    }
                }
            }) {
                Text("Confirm Appointment")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPaymentMethod != nil ? Color.medicareBlue : Color.gray)
                    )
                    .cornerRadius(12)
            }
            .disabled(selectedPaymentMethod == nil || isLoading)
            
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
            .disabled(isLoading)
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
        .alert("Confirm Payment", isPresented: $showPaymentAlert) {
            Button("Confirm") {
                onConfirm()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your appointment will be booked. Please pay at the counter.")
        }
    }
}

// Helper view for detail rows
struct DoctorDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
    }
}
