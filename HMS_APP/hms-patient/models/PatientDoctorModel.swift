import Foundation
import FirebaseFirestore

struct DoctorSchedules: Codable {
    var fullDayLeaves: [String: Int]?
    var leaveTimeSlots: [String: [String: Int]]?
}

struct LicenseDetails: Codable {
    var councilName: String?
    var registrationNumber: Int?
    var verificationStatus: String?
    var verifiedAt: Timestamp?
    var yearOfRegistration: Int?
}

struct DoctorProfile: Identifiable, Codable {
    var id: String?
    let name: String
    let speciality: String
    let database: String?
    let age: Int?
    let schedules: DoctorSchedules?
    let appwriteUserId: String?
    let gender: String?
    let licenseDetails: LicenseDetails?
    let createdAt: Timestamp?
    let lastActive: String?
    // Add other fields as needed
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case speciality
        case database
        case age
        case schedules
        case appwriteUserId
        case gender
        case licenseDetails
        case createdAt
        case lastActive
    }
}

@MainActor
class DoctorViewModel: ObservableObject {
    @Published var doctors: [DoctorProfile] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    func fetchDoctors() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("hms4_doctors").getDocuments()
            self.doctors = try snapshot.documents.compactMap { document in
                let data = document.data()
                let id = document.documentID
                
                guard let name = data["name"] as? String,
                      let speciality = data["speciality"] as? String else {
                    return nil
                }
                
                let database = data["database"] as? String
                let age = data["age"] as? Int
                let appwriteUserId = data["appwriteUserId"] as? String
                let gender = data["gender"] as? String
                let lastActive = data["lastActive"] as? String
                let createdAt = data["createdAt"] as? Timestamp
                
                // Parse schedules
                var schedules: DoctorSchedules? = nil
                if let schedulesData = data["schedules"] as? [String: Any] {
                    let fullDayLeaves = schedulesData["fullDayLeaves"] as? [String: Int]
                    let leaveTimeSlots = schedulesData["leaveTimeSlots"] as? [String: [String: Int]]
                    schedules = DoctorSchedules(fullDayLeaves: fullDayLeaves, leaveTimeSlots: leaveTimeSlots)
                }
                
                // Parse licenseDetails
                var licenseDetails: LicenseDetails? = nil
                if let licenseData = data["licenseDetails"] as? [String: Any] {
                    let councilName = licenseData["councilName"] as? String
                    let registrationNumber = licenseData["registrationNumber"] as? Int
                    let verificationStatus = licenseData["verificationStatus"] as? String
                    let verifiedAt = licenseData["verifiedAt"] as? Timestamp
                    let yearOfRegistration = licenseData["yearOfRegistration"] as? Int
                    licenseDetails = LicenseDetails(
                        councilName: councilName,
                        registrationNumber: registrationNumber,
                        verificationStatus: verificationStatus,
                        verifiedAt: verifiedAt,
                        yearOfRegistration: yearOfRegistration
                    )
                }
                
                return DoctorProfile(
                    id: id,
                    name: name,
                    speciality: speciality,
                    database: database,
                    age: age,
                    schedules: schedules,
                    appwriteUserId: appwriteUserId,
                    gender: gender,
                    licenseDetails: licenseDetails,
                    createdAt: createdAt,
                    lastActive: lastActive
                )
            }
            isLoading = false
        } catch {
            self.error = "Error fetching doctors: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Fetch doctors by speciality
    func fetchDoctorsBySpeciality(_ speciality: String) async {
        isLoading = true
        do {
            let snapshot = try await db.collection("hms4_doctors")
                .whereField("speciality", isEqualTo: speciality)
                .getDocuments()
            
            self.doctors = try snapshot.documents.compactMap { document in
                let data = document.data()
                let id = document.documentID
                
                guard let name = data["name"] as? String,
                      let speciality = data["speciality"] as? String else {
                    return nil
                }
                
                let database = data["database"] as? String
                let age = data["age"] as? Int
                let appwriteUserId = data["appwriteUserId"] as? String
                let gender = data["gender"] as? String
                let lastActive = data["lastActive"] as? String
                let createdAt = data["createdAt"] as? Timestamp
                
                // Parse schedules
                var schedules: DoctorSchedules? = nil
                if let schedulesData = data["schedules"] as? [String: Any] {
                    let fullDayLeaves = schedulesData["fullDayLeaves"] as? [String: Int]
                    let leaveTimeSlots = schedulesData["leaveTimeSlots"] as? [String: [String: Int]]
                    schedules = DoctorSchedules(fullDayLeaves: fullDayLeaves, leaveTimeSlots: leaveTimeSlots)
                }
                
                // Parse licenseDetails
                var licenseDetails: LicenseDetails? = nil
                if let licenseData = data["licenseDetails"] as? [String: Any] {
                    let councilName = licenseData["councilName"] as? String
                    let registrationNumber = licenseData["registrationNumber"] as? Int
                    let verificationStatus = licenseData["verificationStatus"] as? String
                    let verifiedAt = licenseData["verifiedAt"] as? Timestamp
                    let yearOfRegistration = licenseData["yearOfRegistration"] as? Int
                    licenseDetails = LicenseDetails(
                        councilName: councilName,
                        registrationNumber: registrationNumber,
                        verificationStatus: verificationStatus,
                        verifiedAt: verifiedAt,
                        yearOfRegistration: yearOfRegistration
                    )
                }
                
                return DoctorProfile(
                    id: id,
                    name: name,
                    speciality: speciality,
                    database: database,
                    age: age,
                    schedules: schedules,
                    appwriteUserId: appwriteUserId,
                    gender: gender,
                    licenseDetails: licenseDetails,
                    createdAt: createdAt,
                    lastActive: lastActive
                )
            }
            isLoading = false
        } catch {
            self.error = "Error fetching doctors: \(error.localizedDescription)"
            isLoading = false
        }
    }
} 
