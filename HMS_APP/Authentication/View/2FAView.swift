//
//  2FAView.swift
//  HMS
//
//  Created by rjk on 22/04/25.
//

import SwiftUI

struct TwoFAView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var isLoginFlow: Bool
    var userType: String
    var email: String
    @State private var otpFields: [String] = ["", "", "", "", "", ""] // Updated to 6 digits
    @FocusState private var focusedIndex: Int?
    @State private var secondsRemaining = 60
    @State private var timerRunning = true
    @State private var navigateToHome = false
    @State private var errorMessage: String? = nil
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    
    init(isLoginFlow: Bool, email: String, userType: String) {
        self.isLoginFlow = isLoginFlow
        self.email = email
        self.userType = userType
    }

    private var isFormValid: Bool {
        return !otpFields.isEmpty && otpFields.allSatisfy { !$0.isEmpty }
    }

    var body: some View {
        VStack {
            Spacer()
            
            Text("OTP Verification")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.light.tertiary)
                .padding(.bottom, 8)
            
            Text("Please check your email address and write the OTP code you received here.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .padding(.horizontal)
                .foregroundColor(.gray)
            
            if !email.isEmpty {
                Text(email)
                    .foregroundColor(Theme.light.primary)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.top, 4)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                    .padding(.top, 8)
            }
            
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { index in
                    TextField("", text: $otpFields[index])
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .font(.title)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedIndex, equals: index)
                        .onChange(of: otpFields[index]) { newValue in
                            if newValue.count > 1 {
                                otpFields[index] = String(newValue.prefix(1))
                            }
                            if !newValue.isEmpty {
                                triggerHaptic()
                                if index < 5 {
                                    focusedIndex = index + 1
                                } else {
                                    focusedIndex = nil
                                }
                            }
                        }
                }
            }
            .padding(.top, 20)
            
            Text("Didn't receive mail?")
                .padding(.top, 35)
                .padding(.bottom, 2)
            
            if timerRunning {
                HStack {
                    Text("You can resend code in")
                        .padding(.zero)
                    Text("\(secondsRemaining)")
                        .foregroundColor(Theme.light.primary)
                        .padding(.zero)
                    Text("s")
                        .padding(.zero)
                }
            } else {
                Button(action: {
                    resendOTP()
                }) {
                    Text("Resend")
                        .foregroundColor(.blue)
                        .bold()
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await handleOTPSubmission()
                }
            }) {
                Text("NEXT")
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isFormValid ? (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary) : Color.blue.opacity(0.3))
                    .cornerRadius(12)
            }
            .disabled(!isOTPComplete)
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            startTimer()
            focusedIndex = 0
        }
        .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
        .background(
            NavigationLink(
                destination: getDestinationView(),
                isActive: $navigateToHome
            ) {
                EmptyView()
            }
            .hidden()
        )
        .navigationBarBackButtonHidden()
    }

    var isOTPComplete: Bool {
        otpFields.allSatisfy { $0.count == 1 }
    }

    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func startTimer() {
        secondsRemaining = 60
        timerRunning = true
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                timer.invalidate()
                timerRunning = false
            }
        }
    }
    
    private func resendOTP() {
        timerRunning = true
        startTimer()
        
        Task {
            do {
                let authService = AuthService()
                isLoading = true
                authService.email = email
                try await authService.sendEmailOTP()
                isLoading = false
                errorMessage = nil
            } catch {
                isLoading = false
                errorMessage = "Failed to send OTP: \(error.localizedDescription)"
            }
        }
    }

    private func handleOTPSubmission() async {
        let otpCode = otpFields.joined()
        
        do {
            let authService = AuthService()
            try await authService.verifyOTP(secret: otpCode)
            if let userId = UserDefaults.standard.string(forKey: "userId") {
                // Get saved name and email directly from UserDefaults
                let savedName = UserDefaults.standard.string(forKey: "tempUserName") ?? ""
                let savedEmail = UserDefaults.standard.string(forKey: "tempUserEmail") ?? ""
                
                DispatchQueue.main.async {
                    // Use the saved name first, then fallback to authService
                    authManager.login(
                        userId: userId,
                        userName: savedName.isEmpty ? authService.name : savedName,
                        userEmail: savedEmail.isEmpty ? authService.email : savedEmail,
                        userType: userType
                    )
                    navigateToHome = true
                }
            } else {
                errorMessage = "User ID not found after verification"
            }
        } catch {
            errorMessage = "OTP verification failed: \(error.localizedDescription)"
        }
    }
    
    @ViewBuilder
    private func getDestinationView() -> some View {
        if isLoginFlow {
            switch userType {
            case "hospital":
                HospitalView()
            case "doctor":
                HospitalView()
            case "patient":
                HospitalView()
            default:
                ContentView()
            }
        } else {
            // For signup flow
            switch userType {
            case "hospital":
                HospitalEntryView()
            case "doctor":
                HospitalView()
            case "patient":
                HospitalView()
            default:
                ContentView()
            }
        }
    }
}


