import SwiftUI

struct NMCLicenseVerificationView: View {
    @StateObject private var viewModel = NMCLicenseVerificationViewModel()
    @EnvironmentObject var doctorManager: DoctorManager
    @Environment(\.colorScheme) var colorScheme
    @State private var navigateToDashboard = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("NMC License Verification")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? Theme.dark.tertiary : Theme.light.tertiary)
                    .padding(.top, 30)
                
                Text("Please enter your medical license details")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                VStack(spacing: 16) {
                    // Registration Number field
                    VStack(alignment: .leading) {
                        Text("Registration Number")
                            .font(.system(size: 14))
                            .foregroundColor(Color.primary)
                        
                        CustomTextField(
                            placeholder: "Enter registration number",
                            isSecure: false,
                            text: $viewModel.registrationNumber,
                            errorMessage: viewModel.registrationNumberError
                        )
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.registrationNumber) { _ in
                            viewModel.validateRegistrationNumber()
                        }
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Doctor profile display when verified
                if let profile = viewModel.doctorProfile, viewModel.verificationStatus == .verified {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Verified Doctor Information")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding(.top, 10)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                DoctorInfoRow(label: "Name", value: "\(profile.salutation ?? "Dr.") \(profile.full_name)")
                                DoctorInfoRow(label: "Registration", value: profile.registration_number)
                                DoctorInfoRow(label: "Year", value: profile.registration_year)
                                DoctorInfoRow(label: "Council", value: profile.state_medical_council)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
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
                
                // Test with sample data
                Text("Sample data: Try registration number 31702")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
                
                Button(action: {
                    Task {
                        await viewModel.verifyLicense()
                        // If verification succeeds, navigate to dashboard
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
        }
        .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
        .navigationBarBackButtonHidden(false)
        .navigationTitle("NMC Verification")
    }
}

// Helper view for displaying doctor information
struct DoctorInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// ViewModel for NMC License Verification
class NMCLicenseVerificationViewModel: ObservableObject {
    private let service = NMCLicenseVerificationService.shared
    
    @Published var registrationNumber: String = ""
    @Published var speciality: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var verificationStatus: VerificationStatus = .none
    @Published var doctorProfile: NMCLicenseVerificationService.DoctorProfile? = nil
    
    // Validation error messages
    @Published var registrationNumberError: String? = nil
    @Published var specialityError: String? = nil
    
    enum VerificationStatus {
        case none
        case pending
        case verified
        case failed
    }
    
    var isFormValid: Bool {
        return !registrationNumber.isEmpty && 
               !speciality.isEmpty &&
               registrationNumberError == nil &&
               specialityError == nil
    }
    
    func validateRegistrationNumber() {
        if registrationNumber.isEmpty {
            registrationNumberError = "Registration number is required"
        } else {
            registrationNumberError = nil
        }
    }
    
    func validateSpeciality() {
        if speciality.isEmpty {
            specialityError = "Speciality is required"
        } else {
            specialityError = nil
        }
    }
    
    func verifyLicense() async {
        guard !registrationNumber.isEmpty else {
            errorMessage = "Registration number is required."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        verificationStatus = .pending
        
        let result = await service.verifyLicense(registrationNumber: registrationNumber)
        
        DispatchQueue.main.async {
            self.isLoading = false
            
            switch result {
            case .success(let response):
                if response.count == 1, let profile = response.results.first {
                    self.doctorProfile = profile
                    self.verificationStatus = .verified
                    self.successMessage = "License verified successfully for Dr. \(profile.full_name)!"
                    
                    // Store license details in Firestore
                    Task {
                        if let userId = UserDefaults.standard.string(forKey: "userId") {
                            await self.service.storeVerificationResult(
                                userId: userId,
                                doctor: profile,
                                speciality: self.speciality
                            )
                        }
                    }
                } else {
                    self.verificationStatus = .failed
                    self.errorMessage = "No doctor found with the provided registration number."
                }
                
            case .failure(let error):
                self.verificationStatus = .failed
                self.errorMessage = "Verification failed: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    NavigationView {
        NMCLicenseVerificationView()
            .environmentObject(DoctorManager())
    }
}
