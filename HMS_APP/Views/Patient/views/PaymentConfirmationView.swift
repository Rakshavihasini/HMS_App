//
//  PaymentConfirmationView.swift
//  HMS_APP
//
//  Created by rjk on 06/05/25.
//
import SwiftUI

// Payment Confirmation View
struct PaymentConfirmationView: View {
    let doctor: DoctorProfile
    let date: Date
    let time: String
    let reason: String
    let consultationFee: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    @StateObject private var router = Router<ViewPath>()
    
    enum PaymentMethod {
        case counter, online
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
    
    // Add this state variable
    @State private var showingPaymentSheet = false
    
    // Modify the payOnlineButton action
    private var payOnlineButton: some View {
        Button(action: {
            selectedPaymentMethod = .online
            showingPaymentSheet = true  // Show sheet instead of navigating
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
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentGatewayHelper(consultationFee: consultationFee)
                .environmentObject(router)
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
                    Text("Online payment will be available soon")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Save payment method to UserDefaults
                if let method = selectedPaymentMethod {
                    let methodString = method == .counter ? "counter" : "online"
                    UserDefaults.standard.set(methodString, forKey: "selectedPaymentMethod")
                }
                onConfirm()
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
            .disabled(selectedPaymentMethod == nil)
            
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
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
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
