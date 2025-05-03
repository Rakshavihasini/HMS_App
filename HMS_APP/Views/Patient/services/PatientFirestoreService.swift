import Foundation
import FirebaseFirestore

class PatientFirestoreService {
    static let shared = PatientFirestoreService()
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    private init() {
        // Ensure we're using the correct database
        let settings = FirestoreSettings()
        settings.host = "firestore.googleapis.com"
        db.settings = settings
    }
    
    // Add a new patient to Firestore
    func addPatient(userId: String, patient: Patient) async throws {
        let patientData: [String: Any] = [
            "id": patient.id,
            "name": patient.name,
            "number": patient.number as Any,
            "email": patient.email,
            "dob": patient.dateOfBirth as Any,
            "gender": patient.gender as Any,
            "appwriteUserId": userId,
            "createdAt": FirebaseFirestore.FieldValue.serverTimestamp(),
            "database": dbName
        ]
        
        try await db.collection("\(dbName)_patients").document(userId).setData(patientData)
    }
    
    // Get patient details by appwrite userId
    func getPatient(userId: String) async throws -> Patient? {
        let document = try await db.collection("\(dbName)_patients").document(userId).getDocument()
        
        if document.exists, let data = document.data() {
            let dateOfBirth: Date? = (data["dob"] as? Timestamp)?.dateValue()
            
            return Patient(
                id: data["id"] as? String ?? "",
                name: data["name"] as? String ?? "",
                number: data["number"] as? Int,
                email: data["email"] as? String ?? "",
                dateOfBirth: dateOfBirth,
                gender: data["gender"] as? String
            )
        }
        
        return nil
    }
    
    // Create patient if it doesn't exist
    func getOrCreatePatient(userId: String, name: String, email: String, dateOfBirth: Date? = nil, gender: String? = nil) async throws -> Patient {
        if let existingPatient = try? await getPatient(userId: userId) {
            return existingPatient
        }
        
        // Create new patient if one doesn't exist
        let newPatient = Patient(
            id: UUID().uuidString,
            name: name,
            email: email,
            dateOfBirth: dateOfBirth,
            gender: gender
        )
        
        try await addPatient(userId: userId, patient: newPatient)
        return newPatient
    }
    
    // Update patient details
    func updatePatient(userId: String, updatedFields: [String: Any]) async throws {
        try await db.collection("\(dbName)_patients").document(userId).updateData(updatedFields)
    }
    
    // Delete patient record
    func deletePatient(userId: String) async throws {
        try await db.collection("\(dbName)_patients").document(userId).delete()
    }
}
