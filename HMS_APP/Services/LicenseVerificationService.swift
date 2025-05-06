import Foundation
import FirebaseFirestore

class LicenseVerificationService {
    private let apiKey = "d6a06c99eemshdae056fa8d0d0d0p19b714jsn141392db5178"
    private let apiHost = "mci-nmc-doctor-verification.p.rapidapi.com"
    private let baseURL = "https://mci-nmc-doctor-verification.p.rapidapi.com/v3/tasks/async/verify_with_source/nmc_doctor"
    private let statusURL = "https://mci-nmc-doctor-verification.p.rapidapi.com/v3/tasks"
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    func verifyLicense(registrationNo: String, yearOfRegistration: String, councilName: String) async throws -> Bool {
        print("Starting license verification process...")
        
        // Create the request URL
        guard let url = URL(string: baseURL) else {
            throw LicenseVerificationError.invalidURL
        }
        
        // Create headers
        let headers = [
            "x-rapidapi-key": apiKey,
            "x-rapidapi-host": apiHost,
            "Content-Type": "application/json"
        ]
        
        // Create parameters
        let parameters: [String: Any] = [
            "task_id": UUID().uuidString,
            "group_id": UUID().uuidString,
            "data": [
                "registration_no": registrationNo,
                "year_of_registration": yearOfRegistration,
                "council_name": councilName
            ]
        ]
        
        print("Request Parameters: \(parameters)")
        
        // Create the request
        let request = NSMutableURLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 10.0
        )
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        do {
            // Encode the request body using JSONSerialization
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
            
            print("Making initial POST request...")
            print("Request URL: \(url.absoluteString)")
            print("Request Headers: \(headers)")
            print("Request Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            
            // Make the initial API call
            let (data, response) = try await URLSession.shared.data(for: request as URLRequest)
            
            // Print response for debugging
            print("Initial Response: \(String(data: data, encoding: .utf8) ?? "")")
            
            // Check the response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LicenseVerificationError.invalidResponse
            }
            
            print("Initial response status code: \(httpResponse.statusCode)")
            
//             Check if the status code is 202 (Accepted)
            if httpResponse.statusCode == 202 {
                print("Request accepted (202). Doctor can proceed.")
                return true
            }
            
            // For other successful status codes, continue with verification
            guard (200...299).contains(httpResponse.statusCode) else {
                throw LicenseVerificationError.serverError("Server returned status code \(httpResponse.statusCode)")
            }
            
            // Decode the initial response
            let initialResponse = try JSONDecoder().decode(InitialResponse.self, from: data)
            
            // Check for immediate errors
            if let error = initialResponse.error {
                throw LicenseVerificationError.verificationFailed("Verification failed: \(error)")
            }
            
            // Check the request ID
            let requestId = initialResponse.request_id.isEmpty ? initialResponse.task_id : initialResponse.request_id
            
            // Proceed with verifying the status
            return try await executeGetRequest(requestId: requestId)
            
        } catch {
            print("Error during verification: \(error)")
            throw error
        }
    }
    
    private func executeGetRequest(requestId: String) async throws -> Bool {
        print("\nExecuting GET request for request ID: \(requestId)")
        
        // Create URL with query parameter
        guard let url = URL(string: "\(statusURL)?request_id=\(requestId)") else {
            throw LicenseVerificationError.invalidURL
        }
        
        // Create headers for GET request
        let headers = [
            "x-rapidapi-key": apiKey,
            "x-rapidapi-host": apiHost
        ]
        
        // Create the request
        let request = NSMutableURLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 10.0
        )
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        print("\nGET Request Details:")
        print("URL: \(url.absoluteString)")
        print("Headers: \(headers)")
        
        let (data, response) = try await URLSession.shared.data(for: request as URLRequest)
        
        // Print response for debugging
        print("GET Response:")
        print(String(data: data, encoding: .utf8) ?? "No response data")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseVerificationError.invalidResponse
        }
        
        print("GET response status code: \(httpResponse.statusCode)")
        
        // Check if the status code is 202 (Accepted)
        if httpResponse.statusCode == 202 {
            print("Request accepted (202). Doctor can proceed.")
            return true
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw LicenseVerificationError.serverError("GET request failed with code \(httpResponse.statusCode)")
        }
        
        let statusResponse = try JSONDecoder().decode(VerificationStatusResponse.self, from: data)
        print("GET response decoded. Status: \(statusResponse.status)")
        
        if statusResponse.isFailed {
            print("Verification failed with error: \(statusResponse.error ?? "Unknown")")
            if statusResponse.error == "BAD_REQUEST" {
                throw LicenseVerificationError.badRequest(statusResponse.message ?? "Unknown error")
            }
            throw LicenseVerificationError.verificationFailed(statusResponse.message ?? "Verification failed")
        }
        
        return statusResponse.isVerified
    }
    
    func storeLicenseDetails(userId: String, licenseData: LicenseData) async throws {
        let licenseInfo: [String: Any] = [
            "registrationNumber": licenseData.registration_no,
            "yearOfRegistration": licenseData.year_of_registration,
            "councilName": licenseData.council_name,
            "speciality": licenseData.speciality,
            "verificationStatus": "verified",
            "verifiedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("\(dbName)_doctors").document(userId).updateData([
            "licenseDetails": licenseInfo,
            "speciality": licenseData.speciality
        ])
    }
}
