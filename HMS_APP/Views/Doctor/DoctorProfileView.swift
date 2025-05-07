//import SwiftUI
//
//struct DoctorProfileView: View {
//    @EnvironmentObject var authManager: AuthManager
//    @State private var navigateToUserSelection = false
//    @Environment(\.colorScheme) private var colorScheme
//    @EnvironmentObject var doctorManager: DoctorManager
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var authService = AuthService()
//    @State private var navigateToSignUp = false
//    
//    private var theme: Theme {
//        colorScheme == .dark ? Theme.dark : Theme.light
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                Image(systemName: "person.circle.fill")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .foregroundColor(theme.primary)
//                    .frame(width: 100, height: 100)
//                    .padding(.top, 40)
//
//                if let userInfo = doctorManager.currentUserInfo {
//                    // Doctor's name
//                    if let name = userInfo["name"] as? String {
//                        Text("Dr. \(name)")
//                            .font(.title)
//                            .bold()
//                            .foregroundColor(theme.text)
//                    }
//                    
//                    // Doctor's age
//                    if let age = userInfo["age"] as? Int {
//                        Text("Age: \(age)")
//                            .foregroundColor(.gray)
//                    }
//                    
//                    // Doctor's gender
//                    if let gender = userInfo["gender"] as? String {
//                        Text("Gender: \(gender)")
//                            .foregroundColor(.gray)
//                    }
//                    
//                    // Doctor's speciality
//                    if let speciality = userInfo["speciality"] as? String {
//                        Text("Speciality: \(speciality)")
//                            .foregroundColor(.gray)
//                    }
//                    
//                    // License verification status
//                    if let licenseDetails = userInfo["licenseDetails"] as? [String: Any],
//                       let status = licenseDetails["verificationStatus"] as? String {
//                        HStack {
//                            Text("License Status:")
//                                .foregroundColor(.gray)
//                            Text(status.capitalized)
//                                .foregroundColor(status == "verified" ? .green : .orange)
//                                .fontWeight(.medium)
//                        }
//                    }
////
////                    // Join date if available
////                    if let joinTimestamp = userInfo["joinDate"] as? Double {
////                        let date = Date(timeIntervalSince1970: joinTimestamp)
////                        let formatter = DateFormatter()
////                        formatter.dateStyle = .medium
////                        let dateString = formatter.string(from: date)
////
////                        Text("Joined: \(dateString)")
////                            .foregroundColor(.gray)
////                            .padding(.top, 4)
////                    }
//                } else {
//                    
//                    Text("Loading profile information...")
//                        .foregroundColor(.gray)
//                        .onAppear {
//                            Task {
//                                await doctorManager.fetchCurrentUserInfo()
//                            }
//                        }
//                }
//
//                Spacer()
//
//                Button(action: {
//                    authManager.logout()
//                    navigateToUserSelection = true
//                }){
//                    Text("Logout")
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.red)
//                        .foregroundColor(.white)
//                        .cornerRadius(12)
//                }
//                
//                .padding()
//
//            }
//            .padding()
//        }
//        .navigationDestination(isPresented: $navigateToUserSelection) {
//            UserSelectionView()
//        }
//        .navigationTitle("Profile")
//        .navigationBarTitleDisplayMode(.inline)
//        .background(theme.background.ignoresSafeArea())
//    }
//    private func handleLogout() async {
//        await authService.logout()
//        navigateToSignUp = true
//    }
//}
//
//#Preview {
//    NavigationStack {
//        DoctorProfileView()
//            .environmentObject(DoctorManager())
//    }
//}

import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Doctor Profile View

struct DoctorProfileView: View {
    @StateObject private var doctorManager = DoctorManager()
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Top Navigation
                HStack {
                    Button(action: {
                        // Handle back navigation
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding([.top, .horizontal])

                if let doctor = doctorManager.currentDoctor {
                    // Profile Image & Name
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 4)

                        Text(doctor.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(doctor.speciality)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        if let number = doctor.number {
                            Text("ID: \(number)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 10)

                    // Professional Information
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Professional Information", systemImage: "person.text.rectangle")
                            .font(.headline)
                            .foregroundColor(.black)

                        InfoCard(title: "Email", value: doctor.email, icon: "envelope.fill")
                        if let licenseRegNo = doctor.licenseRegNo {
                            InfoCard(title: "License Number", value: licenseRegNo, icon: "doc.text.fill")
                        }
                        if let smc = doctor.smc {
                            InfoCard(title: "Medical Council", value: smc, icon: "building.columns.fill")
                        }
                        if let yearOfRegistration = doctor.yearOfRegistration {
                            InfoCard(title: "Registration Year", value: String(yearOfRegistration), icon: "calendar")
                        }
                        if let gender = doctor.gender {
                            InfoCard(title: "Gender", value: gender, icon: "person.fill")
                        }
                        if let age = doctor.age {
                            InfoCard(title: "Age", value: "\(age) years", icon: "person.fill")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Schedule Information
                    if let schedule = doctor.schedule {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Schedule Information", systemImage: "calendar")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            if let fullDayLeaves = schedule.fullDayLeaves, !fullDayLeaves.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Full Day Leaves")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    ForEach(fullDayLeaves, id: \.self) { date in
                                        Text(date.formatted(date: .long, time: .omitted))
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            if let leaveTimeSlots = schedule.leaveTimeSlots, !leaveTimeSlots.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Leave Time Slots")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    ForEach(leaveTimeSlots, id: \.self) { date in
                                        Text(date.formatted(date: .long, time: .shortened))
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // License Verification Status
                    if doctorManager.isLicenseVerified {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("License Verified")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Label("Edit Profile", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            Label("Logout", systemImage: "arrow.right.square")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                } else {
                    ProgressView()
                        .padding()
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .alert("Error", isPresented: .constant(doctorManager.error != nil)) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(doctorManager.error ?? "")
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                // Handle logout
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .sheet(isPresented: $showingEditProfile) {
            // Edit Profile View will be implemented here
            Text("Edit Profile View")
        }
    }
}

// MARK: - Supporting Views

struct InfoCard: View {
    var title: String
    var value: String
    var icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    DoctorProfileView()
}
