//
//  PatientDetails.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 01/05/25.
//


import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI

// ObservableObject to fetch patient data

class PatientDetailsService: ObservableObject {
    @Published var patients: [Patient] = []
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    func fetchPatients() {
        db.collection("\(dbName)_patients").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error fetching patients: \(error)")
                return
            }

            if let snapshot = snapshot {
                print("✅ Total Patients: \(snapshot.documents.count)")
                var fetchedPatients: [Patient] = []
                
                // Use for loop to process each document
                for document in snapshot.documents {
                    let data = document.data()
                    print(data)
                    
                    // Parse date fields
                    var dateOfBirth: Date? = nil
                    if let dobTimestamp = data["dob"] as? Timestamp {
                        dateOfBirth = dobTimestamp.dateValue()
                    }
                    
                    // Create patient from document data
                    let patient = Patient(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        number: data["number"] as? Int,
                        email: data["email"] as? String ?? "",
                        dateOfBirth: dateOfBirth,
                        gender: data["gender"] as? String
                    )
                    
                    fetchedPatients.append(patient)
                }
                
                DispatchQueue.main.async {
                    self?.patients = fetchedPatients
                    print("✅ Fetched \(fetchedPatients.count) patients")
                }
            }
        }
    }
    
    // Add a patient to Firestore
    func addPatient(_ patient: Patient, completion: @escaping (Result<Void, Error>) -> Void) {
        let patientData: [String: Any] = [
            "id": patient.id,
            "name": patient.name,
            "number": patient.number as Any,
            "email": patient.email,
            "dob": patient.dateOfBirth as Any,
            "gender": patient.gender as Any,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("\(dbName)_patients").document(patient.id).setData(patientData) { error in
            if let error = error {
                print("❌ Error saving patient: \(error)")
                completion(.failure(error))
            } else {
                print("✅ Patient saved successfully")
                completion(.success(()))
            }
        }
    }
}
