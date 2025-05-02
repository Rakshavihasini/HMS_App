//
//  Doctor.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//

// This model is being replaced by DoctorProfile from DoctorModel.swift
// Keeping for reference only
struct LegacyDoctorModel: Identifiable {
    let id: String
    let name: String
    let qualification: String
    let department: String
    let experience: String
    let hospital: String
    let location: String
    let fee: String
    let availableToday: Bool
    let rating: Double
    let imageName: String  
}
