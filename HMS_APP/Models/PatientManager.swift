//
//  PatientManager.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 30/04/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class PatientManager: ObservableObject {
    @Published var currentUserInfo: [String: Any]?
    @Published var currentPatient: Patient?
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    init() {
        Task {
            await fetchCurrentUserInfo()
        }
    }
    
    @MainActor
    func fetchCurrentUserInfo() async {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            self.error = "No user ID found"
            return
        }
        
        do {
            let docRef = db.collection("\(dbName)_patients").document(userId)
            let document = try await docRef.getDocument()
            
            if document.exists, let data = document.data() {
                self.currentUserInfo = data
                
                // Parse date fields
                var dateOfBirth: Date? = nil
                if let dobTimestamp = data["dob"] as? Timestamp {
                    dateOfBirth = dobTimestamp.dateValue()
                }
                
                self.currentPatient = Patient(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    number: data["number"] as? Int,
                    email: data["email"] as? String ?? "",
                    dateOfBirth: dateOfBirth,
                    gender: data["gender"] as? String
                )
                
                self.error = nil
            } else {
                self.error = "Patient data not found"
            }
        } catch {
            self.error = "Error fetching patient info: \(error.localizedDescription)"
        }
    }
    
    func fetchPastAppointments(completion: @escaping ([AppointmentData]) -> Void) {
        guard let patientId = currentPatient?.id else {
            completion([])
            return
        }

        print("PATIENT ID: \(patientId)")
        
        db.collection("\(dbName)_appointments")
            .whereField("patId", isEqualTo: patientId)
            .whereField("status", in: ["COMPLETED", "CANCELLED"])
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching past appointments: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let appointments = documents.compactMap { document -> AppointmentData? in
                    let data = document.data()
                    print("Data: \(data)")
                    
                    // Parse appointment date
                    var appointmentDateTime: Date? = nil
                    if let timestamp = data["appointmentDateTime"] as? Timestamp {
                        appointmentDateTime = timestamp.dateValue()
                    }
                    
                    // Parse appointment status
                    var status: AppointmentData.AppointmentStatus? = nil
                    if let statusString = data["status"] as? String,
                       let appointmentStatus = AppointmentData.AppointmentStatus(rawValue: statusString) {
                        status = appointmentStatus
                    }
                    
                    return AppointmentData(
                        id: document.documentID,
                        patientId: data["patId"] as? String ?? "",
                        patientName: data["patName"] as? String ?? "",
                        doctorId: data["docId"] as? String ?? "",
                        doctorName: data["docName"] as? String ?? "",
                        patientRecordsId: data["patientRecordsId"] as? String ?? "",
                        appointmentDateTime: appointmentDateTime,
                        status: status,
                        durationMinutes: data["durationMinutes"] as? Int,
                        notes: data["notes"] as? String,
                        date: data["date"] as? String,
                        reason: data["reason"] as? String
                    )
                }
                
                completion(appointments)
            }
    }
    
    func fetchUpcomingAppointments(completion: @escaping ([AppointmentData]) -> Void) {
        guard let patientId = currentPatient?.id else {
            completion([])
            return
        }
        
        db.collection("\(dbName)_appointments")
            .whereField("patId", isEqualTo: patientId)
            .whereField("status", in: ["SCHEDULED", "RESCHEDULED", "WAITING"])
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching upcoming appointments: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let appointments = documents.compactMap { document -> AppointmentData? in
                    let data = document.data()
                    
                    // Parse appointment date
                    var appointmentDateTime: Date? = nil
                    if let timestamp = data["appointmentDateTime"] as? Timestamp {
                        appointmentDateTime = timestamp.dateValue()
                    }
                    
                    // Parse appointment status
                    var status: AppointmentData.AppointmentStatus? = nil
                    if let statusString = data["status"] as? String,
                       let appointmentStatus = AppointmentData.AppointmentStatus(rawValue: statusString) {
                        status = appointmentStatus
                    }
                    
                    return AppointmentData(
                        id: document.documentID,
                        patientId: data["patId"] as? String ?? "",
                        patientName: data["patName"] as? String ?? "",
                        doctorId: data["docId"] as? String ?? "",
                        doctorName: data["docName"] as? String ?? "",
                        patientRecordsId: data["patientRecordsId"] as? String ?? "",
                        appointmentDateTime: appointmentDateTime,
                        status: status,
                        durationMinutes: data["durationMinutes"] as? Int,
                        notes: data["notes"] as? String,
                        date: data["date"] as? String,
                        reason: data["reason"] as? String
                    )
                }
                
                completion(appointments)
            }
    }
    
    func updatePatientProfile(updatedFields: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            completion(false)
            return
        }
        
        db.collection("\(dbName)_patients").document(userId).updateData(updatedFields) { error in
            if let error = error {
                print("Error updating patient profile: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Refresh current user info after update
            Task { [weak self] in
                await self?.fetchCurrentUserInfo()
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }
    }
}