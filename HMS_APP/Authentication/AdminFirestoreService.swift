import Foundation
import FirebaseFirestore

// Define the Admin model
struct Admin: Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let lastActive: String
    let hospitalName: String
}

class AdminFirestoreService {
    static let shared = AdminFirestoreService()
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    private init() {
        // Ensure we're using the correct database
        let settings = FirestoreSettings()
        settings.host = "firestore.googleapis.com"
        db.settings = settings
    }
    
    // Add a new admin to Firestore
    func addAdmin(userId: String, admin: Admin) async throws {
        let adminData: [String: Any] = [
            "id": admin.id,
            "name": admin.name,
            "email": admin.email,
            "role": admin.role,
            "lastActive": admin.lastActive,
            "hospitalName": admin.hospitalName,
            "appwriteUserId": userId,
            "createdAt": FirebaseFirestore.FieldValue.serverTimestamp(),
            "database": dbName
        ]
        
        try await db.collection("\(dbName)_admins").document(userId).setData(adminData)
    }
    
    // Get admin details by appwrite userId
    func getAdmin(userId: String) async throws -> Admin? {
        let document = try await db.collection("\(dbName)_admins").document(userId).getDocument()
        
        if document.exists, let data = document.data() {
            return Admin(
                id: data["id"] as? String ?? "",
                name: data["name"] as? String ?? "",
                email: data["email"] as? String ?? "",
                role: data["role"] as? String ?? "Admin",
                lastActive: data["lastActive"] as? String ?? "",
                hospitalName: data["hospitalName"] as? String ?? "General Hospital"
            )
        }
        
        return nil
    }
    
    // Create admin if it doesn't exist
    func getOrCreateAdmin(userId: String, name: String, email: String, role: String = "Admin", hospitalName: String = "General Hospital") async throws -> Admin {
        if let existingAdmin = try? await getAdmin(userId: userId) {
            return existingAdmin
        }
        
        // Create new admin if one doesn't exist
        let newAdmin = Admin(
            id: UUID().uuidString,
            name: name,
            email: email,
            role: role,
            lastActive: Date().formatted(date: .abbreviated, time: .omitted),
            hospitalName: hospitalName
        )
        
        try await addAdmin(userId: userId, admin: newAdmin)
        return newAdmin
    }
    
    // Update admin details
    func updateAdmin(userId: String, updatedFields: [String: Any]) async throws {
        try await db.collection("\(dbName)_admins").document(userId).updateData(updatedFields)
    }
    
    // Delete admin record
    func deleteAdmin(userId: String) async throws {
        try await db.collection("\(dbName)_admins").document(userId).delete()
    }
    
    // Update last active time
    func updateLastActive(userId: String) async throws {
        let lastActiveDate = Date().formatted(date: .abbreviated, time: .omitted)
        try await updateAdmin(userId: userId, updatedFields: ["lastActive": lastActiveDate])
    }
} 