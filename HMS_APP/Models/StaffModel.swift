////
////  StaffModel.swift
////  Hms
////
////  Created by admin49 on 30/04/25.
////
//
//import Foundation
//
///// A model representing a staff member in the healthcare system
//struct Staff: Identifiable, Codable {
//    /// The unique identifier for the staff member (UUID)
//    let id: String
//    
//    /// The staff member's full name
//    let name: String
//    
//    /// The staff member's date of birth
//    let dateOfBirth: Date?
//    
//    /// The date when the staff member joined the organization
//    let joinDate: Date?
//    
//    /// The staff member's educational qualification
//    let educationalQualification: String?
//    
//    /// The staff member's certificates or degrees
//    let certificates: [String]?
//    
//    /// The role of the staff member in the organization
//    let staffRole: String?
//    
//    /// Creates a new Staff instance
//    /// - Parameters:
//    ///   - id: The unique identifier for the staff member
//    ///   - name: The staff member's full name
//    ///   - dateOfBirth: The staff member's date of birth (optional)
//    ///   - joinDate: The date when the staff member joined the organization (optional)
//    ///   - educationalQualification: The staff member's educational qualification (optional)
//    ///   - certificates: The staff member's certificates or degrees (optional)
//    ///   - staffRole: The role of the staff member in the organization (optional)
//    init(
//        id: String,
//        name: String,
//        dateOfBirth: Date? = nil,
//        joinDate: Date? = nil,
//        educationalQualification: String? = nil,
//        certificates: [String]? = nil,
//        staffRole: String? = nil
//    ) {
//        self.id = id
//        self.name = name
//        self.dateOfBirth = dateOfBirth
//        self.joinDate = joinDate
//        self.educationalQualification = educationalQualification
//        self.certificates = certificates
//        self.staffRole = staffRole
//    }
//    
//    // MARK: - Codable
//    
//    enum CodingKeys: String, CodingKey {
//        case id = "uuid"
//        case name
//        case dateOfBirth = "dob"
//        case joinDate
//        case educationalQualification
//        case certificates
//        case staffRole
//    }
//    
//    // MARK: - Additional functionality
//    
//    /// Calculates the staff member's age based on their date of birth (if available)
//    var age: Int? {
//        guard let dob = dateOfBirth else { return nil }
//        
//        let calendar = Calendar.current
//        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
//        return ageComponents.year
//    }
//    
//    /// Calculates the duration in years for which the staff member has been with the organization
//    var yearsOfService: Int? {
//        guard let joinDate = joinDate else { return nil }
//        
//        let calendar = Calendar.current
//        let serviceComponents = calendar.dateComponents([.year], from: joinDate, to: Date())
//        return serviceComponents.year
//    }
//    
//    /// Returns a formatted string with the staff member's basic information
//    var basicInfo: String {
//        var info = name
//        
//        if let role = staffRole {
//            info += " - \(role)"
//        }
//        
//        if let years = yearsOfService {
//            info += " (\(years) years of service)"
//        }
//        
//        return info
//    }
//    
//    /// Returns a formatted string with the staff member's educational information
//    var educationInfo: String {
//        var info = ""
//        
//        if let qualification = educationalQualification {
//            info += qualification
//        }
//        
//        if let certs = certificates, !certs.isEmpty {
//            if !info.isEmpty {
//                info += " - "
//            }
//            info += certs.joined(separator: ", ")
//        }
//        
//        return info.isEmpty ? "No educational information available" : info
//    }
//}
//
//// MARK: - Extensions for Staff
//
//extension Staff {
//    /// Creates a sample staff member for preview and testing purposes
//    static var sample: Staff {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        let dob = dateFormatter.date(from: "1988-09-15")
//        let joinDate = dateFormatter.date(from: "2018-03-01")
//        
//        return Staff(
//            id: "staff789",
//            name: "Sarah Johnson",
//            dateOfBirth: dob,
//            joinDate: joinDate,
//            educationalQualification: "BSc Nursing",
//            certificates: ["BLS Certification", "ACLS Certification"],
//            staffRole: "Head Nurse"
//        )
//    }
//}
