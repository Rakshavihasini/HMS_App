//
//  DoctorService.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 01/05/25.
//


//
//  DoctorService.swift
//  HMS_Admin
//
//  Created by admin49 on 25/04/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class DoctorService: ObservableObject {
    @Published var doctors: [Doctor] = []
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    func fetchDoctors() {
        db.collection("\(dbName)_doctors").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error fetching doctors: \(error)")
                return
            }
            
            if let snapshot = snapshot {
                print("✅ Total Doctors: \(snapshot.documents.count)")
                var fetchedDoctors: [Doctor] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    print(data)
                    
                    // Parse date fields
                    var dateOfBirth: Date? = nil
                    if let dobTimestamp = data["dob"] as? Timestamp {
                        dateOfBirth = dobTimestamp.dateValue()
                    }
                    
                    // Parse schedule data if it exists
                    var schedule: Doctor.Schedule? = nil
                    if let scheduleData = data["schedule"] as? [String: Any] {
                        var leaveTimeSlots: [Date] = []
                        var fullDayLeaves: [Date] = []
                        
                        // Parse leave time slots
                        if let leaveTimestamps = scheduleData["leaveTimeSlots"] as? [Timestamp] {
                            leaveTimeSlots = leaveTimestamps.map { $0.dateValue() }
                        }
                        
                        // Parse full day leaves
                        if let leaveTimestamps = scheduleData["fullDayLeaves"] as? [Timestamp] {
                            fullDayLeaves = leaveTimestamps.map { $0.dateValue() }
                        }
                        
                        schedule = Doctor.Schedule(
                            leaveTimeSlots: leaveTimeSlots.isEmpty ? nil : leaveTimeSlots,
                            fullDayLeaves: fullDayLeaves.isEmpty ? nil : fullDayLeaves
                        )
                    }
                    
                    let doctor = Doctor(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        number: data["number"] as? Int,
                        email: data["email"] as? String ?? "",
                        licenseRegNo: data["licenseRegNo"] as? String,
                        smc: data["smc"] as? String,
                        gender: data["gender"] as? String,
                        dateOfBirth: dateOfBirth,
                        yearOfRegistration: data["yearOfRegistration"] as? Int,
                        schedule: schedule
                    )
                    fetchedDoctors.append(doctor)
                }
                
                DispatchQueue.main.async {
                    self?.doctors = fetchedDoctors
                    print("✅ Fetched \(fetchedDoctors.count) doctors")
                }
            }
        }
    }
    
    // Add a doctor to Firestore
    func addDoctor(_ doctor: Doctor, completion: @escaping (Result<Void, Error>) -> Void) {
        let docData: [String: Any] = [
            "id": doctor.id,
            "name": doctor.name,
            "number": doctor.number as Any,
            "email": doctor.email,
            "licenseRegNo": doctor.licenseRegNo as Any,
            "smc": doctor.smc as Any,
            "gender": doctor.gender as Any,
            "dob": doctor.dateOfBirth as Any,
            "yearOfRegistration": doctor.yearOfRegistration as Any,
            "createdAt": Timestamp(date: Date())
        ]
        
        // Add schedule data if available
        if let schedule = doctor.schedule {
            var scheduleData: [String: Any] = [:]
            if let leaveTimeSlots = schedule.leaveTimeSlots {
                scheduleData["leaveTimeSlots"] = leaveTimeSlots
            }
            if let fullDayLeaves = schedule.fullDayLeaves {
                scheduleData["fullDayLeaves"] = fullDayLeaves
            }
            
            if !scheduleData.isEmpty {
                var doctorData = docData
                doctorData["schedule"] = scheduleData
                saveDoctor(doctorData, doctor.id, completion)
                return
            }
        }
        
        saveDoctor(docData, doctor.id, completion)
    }
    
    // Helper method to save doctor data
    private func saveDoctor(_ data: [String: Any], _ id: String, _ completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("\(dbName)_doctors").document(id).setData(data) { error in
            if let error = error {
                print("❌ Error saving doctor: \(error)")
                completion(.failure(error))
            } else {
                print("✅ Doctor saved successfully")
                completion(.success(()))
            }
        }
    }
}
