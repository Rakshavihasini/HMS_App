//
//  Admin.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 01/05/25.
//


import Foundation
import FirebaseFirestore

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
    func addAdmin(userId: String, admin: Admin1) async throws {

        let adminData: [String: Any] = [
            "adminId": admin.id,
            "name": admin.name,
            "number": admin.number as Any,
            "email": admin.email,
            "dob": admin.dateOfBirth as Any,
            "gender": admin.gender as Any,
            "role": admin.role as Any,
            "accessLevel": admin.accessLevel?.rawValue as Any,
            "appwriteUserId": userId,
            "createdAt": FirebaseFirestore.FieldValue.serverTimestamp(),
            "database": dbName
        ]
        
        try await db.collection("\(dbName)_admins").document(userId).setData(adminData)
    }
    
    // Get admin details by appwrite userId
    func getAdmin(userId: String) async throws -> Admin1? {

        let document = try await db.collection("\(dbName)_admins").document(userId).getDocument()
        
        if document.exists, let data = document.data() {
            // Create date formatter for date of birth
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Parse date of birth if it exists
            var dob: Date? = nil
            if let dobTimestamp = data["dob"] as? Timestamp {
                dob = dobTimestamp.dateValue()
            } else if let dobString = data["dob"] as? String {
                dob = dateFormatter.date(from: dobString)
            }
            
            // Parse access level
            var accessLevel: Admin1.AccessLevel? = nil
            if let accessLevelString = data["accessLevel"] as? String {
                accessLevel = Admin1.AccessLevel(rawValue: accessLevelString)
            }
            
            return Admin1(
                id: data["adminId"] as? String ?? "",
                name: data["name"] as? String ?? "",
                number: data["number"] as? Int,
                email: data["email"] as? String ?? "",
                dateOfBirth: dob,
                gender: data["gender"] as? String,
                role: data["role"] as? String,
                accessLevel: accessLevel
            )
        }
        
        return nil
    }
    
    // Create admin if it doesn't exist
    func getOrCreateAdmin(userId: String, name: String, email: String, role: String? = nil, accessLevel: Admin1.AccessLevel? = .readonly) async throws -> Admin1 {

        if let existingAdmin = try? await getAdmin(userId: userId) {
            return existingAdmin
        }
        
        // Create new admin if one doesn't exist
        let newAdmin = Admin1(
            id: UUID().uuidString,
            name: name,
            email: email,
            role: role,
            accessLevel: accessLevel
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
