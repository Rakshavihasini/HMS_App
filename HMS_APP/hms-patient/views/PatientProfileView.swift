//
//  PatientProfileView.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//

import SwiftUI
import FirebaseFirestore

struct PatientProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @State private var patient: Patient?
    @State private var isLoading = true
    @State private var patientEmail: String = ""
    @State private var patientName: String = ""
    @State private var patientNumber: Int? = nil
    @State private var patientDateOfBirth: Date? = nil
    @State private var patientGender: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding()
                } else {
                    ProfileHeaderView(patientName: patientName)
                    
                    Divider()
                    
                    ProfileInfoSection(
                        email: patientEmail,
                        number: patientNumber,
                        dateOfBirth: patientDateOfBirth,
                        gender: patientGender
                    )
                }
                
                Button(action: {}) {
                    Text("Edit Profile")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.medicareBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Button(action: { 
                    authManager.logout() 
                }) {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.medicareRed)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Try multiple dismissal methods for better compatibility
                    dismiss()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.medicareBlue)
                }
            }
        }
        .onAppear {
            fetchPatientInfo()
        }
    }
    
    private func fetchPatientInfo() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            isLoading = false
            return
        }
        
        Task {
            do {
                // Fetch from Firestore directly to ensure we have the latest data
                let db = Firestore.firestore()
                let patientDocument = try await db.collection("hms4_patients").document(userId).getDocument()
                
                if patientDocument.exists, let data = patientDocument.data() {
                    // Extract patient information directly from document
                    let patientName = data["name"] as? String ?? "Patient"
                    let patientNumber = data["number"] as? Int
                    let patientGender = data["gender"] as? String
                    let patientId = data["id"] as? String ?? UUID().uuidString
                    let email = data["email"] as? String ?? ""
                    let dateOfBirth = (data["dob"] as? Timestamp)?.dateValue()
                    
                    // Create patient object using the Patient model
                    let patientData = Patient(
                        id: patientId,
                        name: patientName,
                        number: patientNumber,
                        email: email,
                        dateOfBirth: dateOfBirth,
                        gender: patientGender
                    )
                    
                    await MainActor.run {
                        self.patient = patientData
                        self.patientName = patientData.name
                        self.patientEmail = patientData.email
                        self.patientNumber = patientData.number
                        self.patientDateOfBirth = patientData.dateOfBirth
                        self.patientGender = patientData.gender
                        
                        // Try to get email from appwrite data if it's empty
                        if self.patientEmail.isEmpty {
                            self.fetchEmailFromAppwrite(userId: userId)
                        }
                        
                        self.isLoading = false
                    }
                } else {
                    // Fallback to FirestoreService as backup
                    let patientData = try await PatientFirestoreService.shared.getOrCreatePatient(
                        userId: userId,
                        name: "Patient",
                        email: ""
                    )
                    
                    await MainActor.run {
                        self.patient = patientData
                        self.patientName = patientData.name
                        self.patientEmail = patientData.email
                        self.patientNumber = patientData.number
                        self.patientDateOfBirth = patientData.dateOfBirth
                        self.patientGender = patientData.gender
                        self.isLoading = false
                        
                        // Try to get email from appwrite data
                        if self.patientEmail.isEmpty {
                            self.fetchEmailFromAppwrite(userId: userId)
                        }
                    }
                }
            } catch {
                print("Error fetching patient data: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchEmailFromAppwrite(userId: String) {
        // Fallback to default email if we can't fetch it
        Task {
            do {
                let db = Firestore.firestore()
                let userDocument = try await db.collection("users").document(userId).getDocument()
                
                if let userData = userDocument.data(), let email = userData["email"] as? String {
                    await MainActor.run {
                        self.patientEmail = email
                        
                        // Update the patient object with the new email if it exists
                        if let currentPatient = self.patient {
                            self.patient = Patient(
                                id: currentPatient.id,
                                name: currentPatient.name,
                                number: currentPatient.number,
                                email: email,
                                dateOfBirth: currentPatient.dateOfBirth,
                                gender: currentPatient.gender
                            )
                        }
                    }
                }
            } catch {
                print("Error fetching email from Appwrite: \(error.localizedDescription)")
            }
        }
    }
}

struct ProfileHeaderView: View {
    let patientName: String
    
    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.medicareBlue)
            
            Text(patientName.isEmpty ? "Loading..." : patientName)
                .font(.title)
                .bold()
            
            Text("Patient ID: 123456")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct ProfileInfoSection: View {
    var email: String
    var number: Int?
    var dateOfBirth: Date?
    var gender: String?
    
    private var formattedDateOfBirth: String {
        guard let dob = dateOfBirth else { return "Not provided" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dob)
    }
    
    private var formattedNumber: String {
        guard let number = number else { return "Not provided" }
        return "\(number)"
    }
    
    private var age: String {
        guard let dob = dateOfBirth else { return "Not provided" }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        if let age = ageComponents.year {
            return "\(age) years"
        }
        return "Not provided"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ProfileInfoRow(icon: "envelope", text: email.isEmpty ? "Email not available" : email)
            ProfileInfoRow(icon: "number", text: "Patient Number: \(formattedNumber)")
            ProfileInfoRow(icon: "calendar", text: "Date of Birth: \(formattedDateOfBirth)")
            ProfileInfoRow(icon: "person", text: "Gender: \(gender ?? "Not provided")")
            ProfileInfoRow(icon: "clock", text: "Age: \(age)")
            ProfileInfoRow(icon: "phone", text: "(555) 987-6543")
            ProfileInfoRow(icon: "house", text: "123 Main St, Anytown, USA")
            ProfileInfoRow(icon: "heart", text: "Blood Type: O+")
            ProfileInfoRow(icon: "cross.case", text: "Primary Care: Dr. Smith")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.medicareBlue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}
