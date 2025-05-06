import Foundation
import Combine

enum VerificationStatus {   
    case none
    case pending
    case verified
    case failed
}

class LicenseVerificationViewModel: ObservableObject {
    private let service: LicenseVerificationService
    private var cancellables = Set<AnyCancellable>()
    
    @Published var registrationNumber: String = ""
    @Published var yearOfRegistration: String = ""
    @Published var councilName: String = ""
    @Published var speciality: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var verificationStatus: VerificationStatus = .none
    @Published var doctorDetails: DoctorDetails?
    
    // Validation error messages
    @Published var registrationNumberError: String?
    @Published var yearOfRegistrationError: String?
    @Published var councilNameError: String?
    @Published var specialityError: String?
    
    init(service: LicenseVerificationService = LicenseVerificationService()) {
        self.service = service
    }
    
    var isFormValid: Bool {
        return !registrationNumber.isEmpty && 
               !yearOfRegistration.isEmpty && 
               !councilName.isEmpty &&
               !speciality.isEmpty &&
               registrationNumberError == nil &&
               yearOfRegistrationError == nil &&
               councilNameError == nil &&
               specialityError == nil
    }
    
    func validateRegistrationNumber() {
        if registrationNumber.isEmpty {
            registrationNumberError = "Registration number is required"
        } else if !registrationNumber.allSatisfy({ $0.isNumber }) {
            registrationNumberError = "Invalid registration number format"
        } else {
            registrationNumberError = nil
        }
    }
    
    func validateYearOfRegistration() {
        if yearOfRegistration.isEmpty {
            yearOfRegistrationError = "Year of registration is required"
        } else if !yearOfRegistration.allSatisfy({ $0.isNumber }) {
            yearOfRegistrationError = "Year should contain only numbers"
        } else if yearOfRegistration.count != 4 {
            yearOfRegistrationError = "Please enter a valid 4-digit year"
        } else if let year = Int(yearOfRegistration), year < 1950 || year > Calendar.current.component(.year, from: Date()) {
            yearOfRegistrationError = "Please enter a valid year between 1950 and \(Calendar.current.component(.year, from: Date()))"
        } else {
            yearOfRegistrationError = nil
        }
    }
    
    func validateCouncilName() {
        if councilName.isEmpty {
            councilNameError = "Council name is required"
        } else {
            councilNameError = nil
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
        guard isFormValid else {
            errorMessage = "Please correct the errors in the form."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        verificationStatus = .pending
        
        do {
            let isVerified = try await service.verifyLicense(
                registrationNo: registrationNumber,
                yearOfRegistration: yearOfRegistration,
                councilName: councilName
            )
            
            DispatchQueue.main.async {
                self.isLoading = false
                if isVerified {
                    self.verificationStatus = .verified
                    self.successMessage = "License verified successfully!"
                    
                    // Store license details in Firestore
                    Task {
                        if let userId = UserDefaults.standard.string(forKey: "userId") {
                            let licenseData = LicenseData(
                                registration_no: self.registrationNumber,
                                year_of_registration: self.yearOfRegistration,
                                council_name: self.councilName,
                                speciality: self.speciality
                            )
                            try await self.service.storeLicenseDetails(userId: userId, licenseData: licenseData)
                        }
                    }
                } else {
                    self.verificationStatus = .failed
                    self.errorMessage = "License verification failed. Please check your information."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.verificationStatus = .failed
                self.errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
} 
