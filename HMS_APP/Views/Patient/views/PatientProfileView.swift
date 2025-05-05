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
    @State private var navigateToUserSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding()
                    } else if let patient = patient {
                        // Enhanced Profile Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.medicareBlue.opacity(0.2), Color.medicareBlue.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.medicareBlue)
                            }
                            
                            Text(patient.name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 20)
                        
                        // Personal Information Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .foregroundColor(.medicareBlue)
                                    .font(.title3)
                                Text("Personal Information")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                // Patient Number
                                if let number = patient.number {
                                    InfoRow(
                                        icon: "number.circle.fill",
                                        title: "Patient ID",
                                        value: String(format: "HMS-%04d", number),
                                        iconColor: .medicareBlue
                                    )
                                }
                                
                                // Email
                                InfoRow(
                                    icon: "envelope.fill",
                                    title: "Email",
                                    value: patient.email,
                                    iconColor: .medicareBlue
                                )
                                
                                // Date of Birth
                                if let dob = patient.dateOfBirth {
                                    InfoRow(
                                        icon: "calendar.circle.fill",
                                        title: "Date of Birth",
                                        value: formatDate(dob),
                                        iconColor: .medicareBlue
                                    )
                                }
                                
                                // Age
                                if let age = patient.age {
                                    InfoRow(
                                        icon: "clock.fill",
                                        title: "Age",
                                        value: "\(age) years",
                                        iconColor: .medicareBlue
                                    )
                                }
                                
                                // Gender
                                if let gender = patient.gender {
                                    InfoRow(
                                        icon: gender.lowercased() == "male" ? "person.fill" : "person.dress.fill",
                                        title: "Gender",
                                        value: gender,
                                        iconColor: .medicareBlue
                                    )
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                            )
                            .padding(.horizontal)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                    Text("Edit Profile")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.medicareBlue)
                                )
                                .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                authManager.logout()
                                navigateToUserSelection = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Logout")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.medicareRed)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.medicareRed, lineWidth: 1.5)
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .navigationDestination(isPresented: $navigateToUserSelection) {
            UserSelectionView()
        }
        .onAppear {
            fetchPatientInfo()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func fetchPatientInfo() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            isLoading = false
            return
        }
        
        Task {
            do {
                let db = Firestore.firestore()
                let patientDocument = try await db.collection("hms4_patients").document(userId).getDocument()
                
                if patientDocument.exists, let data = patientDocument.data() {
                    let patientData = Patient(
                        id: data["id"] as? String ?? userId,
                        name: data["name"] as? String ?? "Patient",
                        number: data["number"] as? Int,
                        email: data["email"] as? String ?? "",
                        dateOfBirth: (data["dob"] as? Timestamp)?.dateValue(),
                        gender: data["gender"] as? String
                    )
                    
                    await MainActor.run {
                        self.patient = patientData
                        self.isLoading = false
                    }
                } else {
                    let patientData = try await PatientFirestoreService.shared.getOrCreatePatient(
                        userId: userId,
                        name: "Patient",
                        email: ""
                    )
                    
                    await MainActor.run {
                        self.patient = patientData
                        self.isLoading = false
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
}

// Enhanced InfoRow
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 20))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}
