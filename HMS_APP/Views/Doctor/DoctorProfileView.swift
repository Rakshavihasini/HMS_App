//
//  DoctorProfileView.swift
//  HMS_APP
//
//  Created by Rudra Pruthi on 02/05/25.
//

import SwiftUI

struct DoctorProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var doctorManager: DoctorManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService()
    @State private var navigateToSignUp = false
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(theme.primary)
                    .frame(width: 100, height: 100)
                    .padding(.top, 40)

                if let userInfo = doctorManager.currentUserInfo {
                    // Doctor's name
                    if let name = userInfo["name"] as? String {
                        Text("Dr. \(name)")
                            .font(.title)
                            .bold()
                            .foregroundColor(theme.text)
                    }
                    
                    // Doctor's age
                    if let age = userInfo["age"] as? Int {
                        Text("Age: \(age)")
                            .foregroundColor(.gray)
                    }
                    
                    // Doctor's gender
                    if let gender = userInfo["gender"] as? String {
                        Text("Gender: \(gender)")
                            .foregroundColor(.gray)
                    }
                    
                    // Doctor's speciality
                    if let speciality = userInfo["speciality"] as? String {
                        Text("Speciality: \(speciality)")
                            .foregroundColor(.gray)
                    }
                    
                    // License verification status
                    if let licenseDetails = userInfo["licenseDetails"] as? [String: Any],
                       let status = licenseDetails["verificationStatus"] as? String {
                        HStack {
                            Text("License Status:")
                                .foregroundColor(.gray)
                            Text(status.capitalized)
                                .foregroundColor(status == "verified" ? .green : .orange)
                                .fontWeight(.medium)
                        }
                    }
//                    
//                    // Join date if available
//                    if let joinTimestamp = userInfo["joinDate"] as? Double {
//                        let date = Date(timeIntervalSince1970: joinTimestamp)
//                        let formatter = DateFormatter()
//                        formatter.dateStyle = .medium
//                        let dateString = formatter.string(from: date)
//                        
//                        Text("Joined: \(dateString)")
//                            .foregroundColor(.gray)
//                            .padding(.top, 4)
//                    }
                } else {
                    
                    Text("Loading profile information...")
                        .foregroundColor(.gray)
                        .onAppear {
                            Task {
                                await doctorManager.fetchCurrentUserInfo()
                            }
                        }
                }

                Spacer()

                Button(action: {
                    Task {
                        await handleLogout()
                    }
                }) {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()

            }
            .padding()
        }
        .navigationDestination(isPresented: $navigateToSignUp) {
            SignUpScreen(userType: "doctor")
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(theme.background.ignoresSafeArea())
    }
    private func handleLogout() async {
        await authService.logout()
        navigateToSignUp = true
    }
}

#Preview {
    NavigationStack {
        DoctorProfileView()
            .environmentObject(DoctorManager())
    }
}
