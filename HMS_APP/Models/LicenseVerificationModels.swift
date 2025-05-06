import Foundation

struct LicenseData: Codable {
    let registration_no: String
    let year_of_registration: String
    let council_name: String
    let speciality: String
    
    enum CodingKeys: String, CodingKey {
        case registration_no = "registration_number"
        case year_of_registration = "year_of_registration"
        case council_name = "council_name"
        case speciality
    }
}

struct LicenseVerificationRequest: Codable {
    let task_id: String
    let group_id: String
    let data: LicenseData
    
    init(task_id: String = UUID().uuidString,
         group_id: String = UUID().uuidString,
         data: LicenseData) {
        self.task_id = task_id
        self.group_id = group_id
        self.data = data
    }
}

struct InitialResponse: Codable {
    let request_id: String
    let task_id: String
    let group_id: String
    let type: String
    let action: String
    let status: String
    let created_at: String
    let completed_at: String?
    let message: String?
    let error: String?
}

struct VerificationStatusResponse: Codable {
    let request_id: String
    let task_id: String
    let group_id: String
    let type: String
    let action: String
    let status: String
    let created_at: String
    let completed_at: String?
    let message: String?
    let error: String?
    let verification_status: String?
    
    var isVerified: Bool {
        status.lowercased() == "completed" && 
        error == nil && 
        verification_status?.lowercased() == "verified"
    }
    
    var isFailed: Bool {
        status.lowercased() == "failed" || error != nil
    }
}

struct TaskResult: Codable {
    let status: String
    let data: VerificationResult?
    let error: String?
}

struct VerificationResult: Codable {
    let verification_status: String
    let doctor_details: DoctorDetails?
    
    var isVerified: Bool {
        verification_status.lowercased() == "verified"
    }
}

struct DoctorDetails: Codable {
    let doctor_name: String
    let registration_number: String
    let registration_date: String
    let council_name: String
    let valid_until: String?
    let specialization: String?
    
    var name: String { doctor_name }
    var registrationNumber: String { registration_number }
    var registrationDate: String { registration_date }
    var councilName: String { council_name }
    var validUntil: String? { valid_until }
}

enum LicenseVerificationError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case serverError(String)
    case verificationFailed(String)
    case badRequest(String)
} 