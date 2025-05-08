import Foundation
import FirebaseFirestore

class NMCLicenseVerificationService {
    static let shared = NMCLicenseVerificationService()
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    private init() {}
    
    // Model to represent the actual response format
    struct NMCVerificationResponse: Codable {
        let results: [DoctorProfile]
        let count: Int
    }
    
    struct DoctorProfile: Codable, Identifiable {
        let profile_id: Int
        let full_name: String
        let salutation: String?
        let registration_number: String
        let registration_year: String
        let state_medical_council: String
        let profile_photo: String?
        
        var id: Int { profile_id }
    }
    
    func verifyLicense(registrationNumber: String) async -> Result<NMCVerificationResponse, Error> {
        // Construct the URL with query parameters
        var components = URLComponents(string: "https://nmr-nmc.abdm.gov.in/api/nmr/v1/health-professional/search")
        components?.queryItems = [
            URLQueryItem(name: "registrationNumber", value: registrationNumber),
            URLQueryItem(name: "profileStatusId", value: "2"),
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "size", value: "9")
        ]
        
        guard let url = components?.url else {
            return .failure(NSError(domain: "LicenseVerificationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers from the provided request
        request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.addValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        request.addValue("gzip, deflate, br, zstd", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("undefined", forHTTPHeaderField: "x-hash")
        request.addValue("eyJ4NXQiOiJOMkpqTWpOaU0yRXhZalJrTnpaalptWTFZVEF4Tm1GbE5qZzRPV1UxWVdRMll6YzFObVk1TlE9PSIsImtpZCI6ImdhdGV3YXlfY2VydGlmaWNhdGVfYWxpYXMiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbkBjYXJib24uc3VwZXIiLCJhcHBsaWNhdGlvbiI6eyJvd25lciI6ImFkbWluIiwidGllclF1b3RhVHlwZSI6bnVsbCwidGllciI6IlVubGltaXRlZCIsIm5hbWUiOiJjb3VuY2lsIiwiaWQiOjE3NiwidXVpZCI6ImY4MTU2ZjAyLTRmZTAtNGE3NS1iNTIxLTg0NjY5MTc2M2I5ZiJ9LCJpc3MiOiJodHRwczpcL1wvYXBpbS5hYmRtLmdvdi5pbjo0NDNcL29hdXRoMlwvdG9rZW4iLCJ0aWVySW5mbyI6eyJVbmxpbWl0ZWQiOnsidGllclF1b3RhVHlwZSI6InJlcXVlc3RDb3VudCIsImdyYXBoUUxNYXhDb21wbGV4aXR5IjowLCJncmFwaFFMTWF4RGVwdGgiOjAsInN0b3BPblF1b3RhUmVhY2giOnRydWUsInNwaWtlQXJyZXN0TGltaXQiOjAsInNwaWtlQXJyZXN0VW5pdCI6bnVsbH19LCJrZXl0eXBlIjoiUFJPRFVDVElPTiIsInBlcm1pdHRlZFJlZmVyZXIiOiIiLCJzdWJzY3JpYmVkQVBJcyI6W3sic3Vic2NyaWJlclRlbmFudERvbWFpbiI6ImNhcmJvbi5zdXBlciIsIm5hbWUiOiJjb3VuY2lsLXNvZnR3YXJlIiwiY29udGV4dCI6IlwvYXBpXC9ubXJcL3YxIiwicHVibGlzaGVyIjoiYWRtaW4iLCJ2ZXJzaW9uIjoidjEiLCJzdWJzY3JpcHRpb25UaWVyIjoiVW5saW1pdGVkIn1dLCJ0b2tlbl90eXBlIjoiYXBpS2V5IiwicGVybWl0dGVkSVAiOiIiLCJpYXQiOjE2OTkzMzM2NDEsImp0aSI6ImQyZjg5MmUzLTY2ZmMtNGFhMi1iYTVjLTY0NWFiYWI1OTEzYiJ9.Pg05blTB-ObtAtyS7muZHE2ze0SwxuFDjkvrh0vMGS0WB7RkBpnUMyuuAIERk56nHHJp2g-6AyeiKvgFr1pxV6rD-9sWSI7E8hN2w-QAnuuM7hw_MbTWDAg95o6hiFCPaZgVInNJc9aNGiFeSxLttFa1x8SRbU1E2g1uSN9APvvBuXvEfBviohEMKMeV2u1_TRsLiUFvIqIpqtES1e6Wgy-nLxUN8V_Xpx0Mh3CyGh6-MoVK3DU4E8OUnBTZmj4ZVVHVHevlS_KiZEKlrzeS7OY-CkXYhOUisc37gVsIHO2pYPC77fu90zBLdY52HUi3x9WpfmfRm7T6cJZCE1H4pg==", forHTTPHeaderField: "apikey")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Print the raw response data
            print("API Response for registration number \(registrationNumber):")
            if let responseString = String(data: data, encoding: .utf8) {
                print(responseString)
            } else {
                print("Could not convert response data to string")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "LicenseVerificationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                do {
                    let result = try decoder.decode(NMCVerificationResponse.self, from: data)
                    print("Successfully decoded response with \(result.count) professionals")
                    
                    // Check if count is 1 (doctor verified)
                    if result.count == 1 {
                        // If count is 1, store the verification in Firestore
                        if let doctor = result.results.first, let userId = UserDefaults.standard.string(forKey: "userId") {
                            await storeVerificationResult(userId: userId, doctor: doctor, speciality: "")
                        }
                        return .success(result)
                    } else {
                        // Still return success but the verification status will be determined by the count
                        return .success(result)
                    }
                } catch {
                    print("Decoding error: \(error)")
                    return .failure(error)
                }
            } else {
                return .failure(NSError(domain: "LicenseVerificationService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"]))
            }
        } catch {
            print("Network error: \(error)")
            return .failure(error)
        }
    }
    
    // Store verification result in Firestore
    func storeVerificationResult(userId: String, doctor: DoctorProfile, speciality: String) async {
        do {
            let licenseInfo: [String: Any] = [
                "registrationNumber": doctor.registration_number,
                "yearOfRegistration": doctor.registration_year,
                "councilName": doctor.state_medical_council,
                "speciality": speciality,
                "verificationStatus": "verified",
                "verifiedAt": FieldValue.serverTimestamp(),
                "fullName": doctor.full_name,
                "salutation": doctor.salutation ?? "Dr."
            ]
            
            try await db.collection("\(dbName)_doctors").document(userId).updateData([
                "licenseDetails": licenseInfo,
                "speciality": speciality,
                "name": doctor.full_name
            ])
            
            print("Successfully stored verification result in Firestore")
        } catch {
            print("Error storing verification result: \(error)")
        }
    }
}
