import SwiftUI

struct LicenseVerificationView: View {
    @StateObject private var viewModel = LicenseVerificationViewModel()
    @EnvironmentObject var doctorManager: DoctorManager
    @Environment(\.colorScheme) var colorScheme
    @State private var navigateToDashboard = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("License Verification")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Theme.dark.tertiary : Theme.light.tertiary)
                    .padding(.top, 30)
                
                Text("Please enter your medical license details")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                VStack(spacing: 16) {
                    CustomTextField(
                        placeholder: "Registration Number",
                        isSecure: false,
                        text: $viewModel.registrationNumber,
                        errorMessage: viewModel.registrationNumberError
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.registrationNumber) { _ in
                        viewModel.validateRegistrationNumber()
                    }
                    
                    // Speciality picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Speciality")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Picker("Speciality", selection: $viewModel.speciality) {
                            Text("Select Speciality").tag("")
                            Text("General Physician").tag("General Physician")
                            Text("Cardiologist").tag("Cardiologist")
                            Text("Dermatologist").tag("Dermatologist")
                            Text("Pediatrician").tag("Pediatrician")
                            Text("Orthopedic").tag("Orthopedic")
                            Text("Neurologist").tag("Neurologist")
                            Text("Psychiatrist").tag("Psychiatrist")
                            Text("Gynecologist").tag("Gynecologist")
                            Text("Ophthalmologist").tag("Ophthalmologist")
                            Text("ENT Specialist").tag("ENT Specialist")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .onChange(of: viewModel.speciality) { _ in
                            viewModel.validateSpeciality()
                        }
                        
                        if let error = viewModel.specialityError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    
                    CustomTextField(
                        placeholder: "Year of Registration",
                        isSecure: false,
                        text: $viewModel.yearOfRegistration,
                        errorMessage: viewModel.yearOfRegistrationError
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.yearOfRegistration) { _ in
                        viewModel.validateYearOfRegistration()
                    }
                    
                    // Council name picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medical Council")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Picker("Medical Council", selection: $viewModel.councilName) {
                            Text("Select Council").tag("")
                            Text("Bombay Medical Council").tag("Bombay Medical Council")
                            Text("Delhi Medical Council").tag("Delhi Medical Council")
                            Text("Karnataka Medical Council").tag("Karnataka Medical Council")
                            Text("Tamil Nadu Medical Council").tag("Tamil Nadu Medical Council")
                            Text("Andhra Pradesh Medical Council").tag("Andhra Pradesh Medical Council")
                            Text("Uttar Pradesh Medical Council").tag("Uttar Pradesh Medical Council")
                            Text("Punjab Medical Council").tag("Punjab Medical Council")
                            Text("Bihar Medical Council").tag("Bihar Medical Council")
                            Text("Gujarat Medical Council").tag("Gujarat Medical Council")
                            Text("Rajasthan Medical Council").tag("Rajasthan Medical Council")
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .onChange(of: viewModel.councilName) { _ in
                            viewModel.validateCouncilName()
                        }
                        
                        if let error = viewModel.councilNameError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 10)
            }
            
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                    .padding(.top, 10)
            }
            
            Spacer()
            
            // For testing with the sample data
            if viewModel.verificationStatus != .verified {
                Text("Sample data: 26986 / 1982 / Bombay Medical Council")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
            }
            
            Button(action: {
                Task {
                    await viewModel.verifyLicense()
                    // If verification succeeds, navigate to dashboard0
                    if viewModel.verificationStatus == .verified {
                        doctorManager.isLicenseVerified = true
                        navigateToDashboard = true
                    }
                }
            }) {
                HStack {
                    Text("VERIFY & CONTINUE")
                        .fontWeight(.bold)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isFormValid ? (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary) : Color.blue.opacity(0.3))
                .cornerRadius(12)
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            .padding(.bottom, 30)
            .padding(.horizontal, 20)
            
            NavigationLink(destination: DoctorTabView().environmentObject(doctorManager), isActive: $navigateToDashboard) {
                EmptyView()
            }
        }
        .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    LicenseVerificationView()
        .environmentObject(DoctorManager())
}
