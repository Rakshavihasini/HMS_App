import SwiftUI
import FirebaseFirestore

struct DoctorProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var doctorManager: DoctorManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService()
    
    // Doctor data
    @State private var doctor: Doctor?
    @State private var isLoading = true
    @State private var navigateToSignUp = false
    @State private var userName: String = ""
    @State private var createdAt: Date?
    @State private var verificationStatus: String = ""
    @State private var verifiedAt: Date?
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    // Date formatter for displaying dates
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    loadingSection
                } else {
                    profileHeaderSection
                    professionalInfoSection
                    contactInfoSection
                    accountInfoSection
                    logoutSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                }
            }
            .onAppear {
                fetchDoctorInfo()
            }
            .background(theme.background)
            .navigationDestination(isPresented: $navigateToSignUp) {
                UserSelectionView()
            }
        }
    }
    
    // MARK: - View Components
    
    private var loadingSection: some View {
        Section {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .listRowBackground(theme.card)
    }
    
    private var profileHeaderSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(theme.primary)
                    .overlay(
                        Circle()
                            .stroke(theme.border, lineWidth: 2)
                    )
                
                Text(doctor?.name.isEmpty ?? true ? "Dr. Name" : "Dr. \(doctor!.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.text)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets())
            .listRowBackground(theme.card)
        }
    }
    
    private var professionalInfoSection: some View {
        Section(header: Text("Professional Information")) {
            ProfileInfoRow(
                icon: "stethoscope",
                label: doctor?.speciality ?? "",
                placeholder: "Speciality",
                isEditable: false,
                text: .constant(""),
                onChange: {}
            )
            
            ProfileInfoRow(
                icon: "building.2",
                label: doctor?.smc ?? "",
                placeholder: "State Medical Council",
                isEditable: false,
                text: .constant(""),
                onChange: {}
            )
            
            ProfileInfoRow(
                icon: "checkmark.circle",
                label: verificationStatus,
                placeholder: "Verification Status",
                isEditable: false,
                text: .constant(""),
                onChange: {}
            )
        }
        .listRowBackground(theme.card)
    }
    
    private var contactInfoSection: some View {
        Section(header: Text("Contact Information")) {
            ProfileInfoRow(
                icon: "envelope",
                label: doctor?.email ?? "",
                placeholder: "Email Address",
                isEditable: false,
                text: .constant(""),
                onChange: {}
            )
        }
        .listRowBackground(theme.card)
    }
    
    private var accountInfoSection: some View {
        Section(header: Text("Account Information")) {
            ProfileInfoRow(
                icon: "person.text.rectangle",
                label: userName,
                placeholder: "Username",
                isEditable: false,
                text: .constant(""),
                onChange: {}
            )
            
            ProfileInfoRow(
                icon: "calendar.badge.plus",
                label: createdAt.map { dateFormatter.string(from: $0) } ?? "",
                placeholder: "Account Created At",
                isEditable: false,
                text: .constant(""),
                onChange: {}
            )
        }
        .listRowBackground(theme.card)
    }
    
    private var logoutSection: some View {
        Section {
            Button(action: {
                Task {
                    await handleLogout()
                }
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listRowBackground(theme.card)
    }
    
    private var backButton: some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(theme.primary)
        }
    }
    
    // MARK: - Data Handling
    
    private func handleLogout() async {
        await authService.logout()
        navigateToSignUp = true
    }
    
    // MARK: - Data Fetching
    
    private func fetchDoctorInfo() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            isLoading = false
            return
        }
        
        Task {
            do {
                let db = Firestore.firestore()
                let doctorDocument = try await db.collection("hms4_doctors").document(userId).getDocument()
                
                if doctorDocument.exists, let data = doctorDocument.data() {
                    var smc: String?
                    var verificationStatus: String = ""
                    var verifiedAt: Date?
                    
                    if let licenseDetails = data["licenseDetails"] as? [String: Any] {
                        smc = licenseDetails["councilName"] as? String
                        verificationStatus = licenseDetails["verificationStatus"] as? String ?? ""
                        if let verifiedTimestamp = licenseDetails["verifiedAt"] as? Timestamp {
                            verifiedAt = verifiedTimestamp.dateValue()
                        }
                    }
                    
                    let createdAt: Date?
                    if let createdTimestamp = data["createdAt"] as? Timestamp {
                        createdAt = createdTimestamp.dateValue()
                    } else {
                        createdAt = nil
                    }
                    
                    let doctorData = Doctor(
                        id: doctorDocument.documentID,
                        name: data["name"] as? String ?? "Doctor",
                        number: nil,
                        email: data["email"] as? String ?? "",
                        speciality: data["speciality"] as? String ?? "",
                        licenseRegNo: nil, // Not fetched
                        smc: smc,
                        gender: nil,
                        dateOfBirth: nil,
                        yearOfRegistration: nil, // Not fetched
                        schedule: nil // Not fetched
                    )
                    
                    await MainActor.run {
                        self.doctor = doctorData
                        self.userName = data["userName"] as? String ?? ""
                        self.createdAt = createdAt
                        self.verificationStatus = verificationStatus
                        self.verifiedAt = verifiedAt
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        isLoading = false
                    }
                }
            } catch {
                print("Error fetching doctor data: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview
struct DoctorProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DoctorProfileView()
                .environmentObject(DoctorManager())
                .preferredColorScheme(.light)
        }
        
        NavigationStack {
            DoctorProfileView()
                .environmentObject(DoctorManager())
                .preferredColorScheme(.dark)
        }
    }
}

