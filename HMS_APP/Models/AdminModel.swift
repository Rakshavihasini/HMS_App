////
////  AdminModel.swift
////  Hms
////
////  Created by admin49 on 30/04/25.
////
//
//import Foundation
//
///// A model representing an administrator in the healthcare system
//struct Admin1: Identifiable, Codable {
//    /// The unique identifier for the admin, used by the Appwrite backend
//    let id: String
//    
//    /// The admin's full name
//    let name: String
//    
//    /// The admin's numeric identifier (optional)
//    let number: Int?
//    
//    /// The admin's email address for contact
//    let email: String
//    
//    /// The admin's date of birth
//    let dateOfBirth: Date?
//    
//    /// The admin's gender
//    let gender: String?
//    
//    /// The admin's role/position in the organization
//    let role: String?
//    
//    /// The admin's access level (determines what they can access)
//    let accessLevel: AccessLevel?
//    
//    /// Enum representing possible admin access levels
//    enum AccessLevel: String, Codable {
//        case superAdmin = "SUPER_ADMIN"
//        case systemAdmin = "SYSTEM_ADMIN"
//        case supportAdmin = "SUPPORT_ADMIN"
//        case readonly = "READONLY"
//    }
//    
//    /// Creates a new Admin instance
//    /// - Parameters:
//    ///   - id: The unique identifier for the admin
//    ///   - name: The admin's full name
//    ///   - number: The admin's numeric identifier (optional)
//    ///   - email: The admin's email address
//    ///   - dateOfBirth: The admin's date of birth (optional)
//    ///   - gender: The admin's gender (optional)
//    ///   - role: The admin's role/position in the organization (optional)
//    ///   - accessLevel: The admin's access level (optional)
//    init(
//        id: String,
//        name: String,
//        number: Int? = nil,
//        email: String,
//        dateOfBirth: Date? = nil,
//        gender: String? = nil,
//        role: String? = nil,
//        accessLevel: AccessLevel? = nil
//    ) {
//        self.id = id
//        self.name = name
//        self.number = number
//        self.email = email
//        self.dateOfBirth = dateOfBirth
//        self.gender = gender
//        self.role = role
//        self.accessLevel = accessLevel
//    }
//    
//    // MARK: - Codable
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "adminId"
//        case name
//        case number
//        case email
//        case dateOfBirth = "dob"
//        case gender
//        case role
//        case accessLevel
//    }
//    
//    // MARK: - Additional functionality
//    
//    /// Calculates the admin's age based on their date of birth (if available)
//    var age: Int? {
//        guard let dob = dateOfBirth else { return nil }
//        
//        let calendar = Calendar.current
//        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
//        return ageComponents.year
//    }
//    
//    /// Returns a formatted string of the admin's basic information
//    var basicInfo: String {
//        var info = name
//        
//        if let role = role {
//            info += " - \(role)"
//        }
//        
//        if let accessLevel = accessLevel {
//            info += " (\(accessLevel.rawValue))"
//        }
//        
//        return info
//    }
//    
//    /// Checks if the admin has super admin privileges
//    var isSuperAdmin: Bool {
//        return accessLevel == .superAdmin
//    }
//    
//    /// Checks if the admin has at least the specified access level
//    /// - Parameter minimumLevel: The minimum access level to check for
//    /// - Returns: A boolean indicating if the admin has at least the specified access level
//    func hasAccessLevel(_ minimumLevel: AccessLevel) -> Bool {
//        guard let currentLevel = accessLevel else { return false }
//        
//        switch (currentLevel, minimumLevel) {
//        case (.superAdmin, _):
//            return true
//        case (.systemAdmin, .superAdmin):
//            return false
//        case (.systemAdmin, _):
//            return true
//        case (.supportAdmin, .superAdmin), (.supportAdmin, .systemAdmin):
//            return false
//        case (.supportAdmin, _):
//            return true
//        case (.readonly, .readonly):
//            return true
//        default:
//            return false
//        }
//    }
//}
//
//// MARK: - Extensions for Admin
//
//extension Admin1 {
//    /// Creates a sample admin for preview and testing purposes
//    static var sample: Admin1 {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let dob = dateFormatter.date(from: "1982-11-10")
//        
//        return Admin1(
//            id: "admin456",
//            name: "Michael Chen",
//            number: 9876,
//            email: "michael.chen@healthsystem.org",
//            dateOfBirth: dob,
//            gender: "Male",
//            role: "IT Department Manager",
//            accessLevel: .systemAdmin
//        )
//    }
//}
