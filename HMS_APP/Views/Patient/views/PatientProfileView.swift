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
    @Environment(\.colorScheme) private var colorScheme
    
    // Patient data
    @State private var patient: Patient?
    @State private var isLoading = true
    
    // Form fields
    @State private var patientEmail: String = ""
    @State private var patientName: String = ""
    @State private var patientDateOfBirth: Date? = nil
    @State private var selectedGender: String = ""
    @State private var selectedBloodType: String = ""
    @State private var phoneNumber: String = ""
    @State private var address: String = ""
    
    // UI state
    @State private var isEditing = false
    @State private var showSaveConfirmation = false
    @State private var navigateToUserSelection = false
    
    private let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    private let bloodTypeOptions = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    private var calculatedAge: String {
        guard let dob = patientDateOfBirth else { return "Not Set" }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dob, to: now)
        if let age = ageComponents.year {
            return "\(age) years"
        }
        return "Not Set"
    }
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    loadingSection
                } else {
                    profileHeaderSection
                    personalInfoSection
                    contactInfoSection
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
            .onAppear {
                loadFromUserDefaults()
                fetchPatientInfo()
            }
            .background(theme.background)
            .alert("Changes Saved", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            }
            .navigationDestination(isPresented: $navigateToUserSelection) {
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
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(theme.primary)
                        .overlay(
                            Circle()
                                .stroke(theme.border, lineWidth: 2)
                        )
                    
                    if isEditing {
                        Button(action: {}) {
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(theme.primary)
                                .background(theme.background)
                                .clipShape(Circle())
                        }
                        .offset(x: 8, y: 8)
                    }
                }
                
                Text(patientName.isEmpty ? "Patient Name" : patientName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.text)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets())
            .listRowBackground(theme.card)
        }
    }
    
    private var personalInfoSection: some View {
        Section(header: Text("Personal Information")) {
            DatePickerRow(
                icon: "calendar",
                label: "Date of Birth",
                date: $patientDateOfBirth,
                isEditing: isEditing,
                placeholder: "Select Date of Birth",
                onChange: saveDateOfBirth
            )
            
            ProfileInfoRow(
                icon: "clock",
                label: calculatedAge,
                placeholder: "Age will be calculated",
                isEditable: false,
                text: .constant(""),
                onChange: {}
            )
            
            PickerRow(
                icon: "person",
                label: "Gender",
                selection: $selectedGender,
                options: genderOptions,
                isEditing: isEditing,
                placeholder: "Select Gender",
                onChange: saveGender
            )
            
            PickerRow(
                icon: "heart",
                label: "Blood Type",
                selection: $selectedBloodType,
                options: bloodTypeOptions,
                isEditing: isEditing,
                placeholder: "Select Blood Type",
                onChange: saveBloodType
            )
        }
        .listRowBackground(theme.card)
    }
    
    private var contactInfoSection: some View {
        Section(header: Text("Contact Information")) {
            ProfileInfoRow(
                icon: "envelope",
                label: patientEmail,
                placeholder: "Enter email address",
                isEditable: isEditing,
                text: $patientEmail,
                onChange: saveEmail
            )
            
            ProfileInfoRow(
                icon: "phone",
                label: phoneNumber,
                placeholder: "Enter phone number",
                isEditable: isEditing,
                text: $phoneNumber,
                onChange: savePhoneNumber
            )
            
            ProfileInfoRow(
                icon: "house",
                label: address,
                placeholder: "Enter full address",
                isEditable: isEditing,
                text: $address,
                onChange: saveAddress
            )
        }
        .listRowBackground(theme.card)
    }
    
    private var logoutSection: some View {
        Section {
            Button(action: {
                authManager.logout()
                navigateToUserSelection = true
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(theme.primary)
        }
    }
    
    private var editButton: some View {
        Button(isEditing ? "Done" : "Edit") {
            withAnimation {
                isEditing.toggle()
                if !isEditing {
                    saveAllChanges()
                    showSaveConfirmation = true
                }
            }
        }
        .foregroundColor(theme.primary)
    }
    
    // MARK: - Data Handling
    
    private func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        phoneNumber = defaults.string(forKey: "patientPhoneNumber") ?? ""
        address = defaults.string(forKey: "patientAddress") ?? ""
        selectedBloodType = defaults.string(forKey: "patientBloodType") ?? ""
        selectedGender = defaults.string(forKey: "patientGender") ?? ""
        
        if let savedDate = defaults.object(forKey: "patientDateOfBirth") as? Date {
            patientDateOfBirth = savedDate
        }
    }
    
    private func saveAllChanges() {
        savePhoneNumber()
        saveAddress()
        saveBloodType()
        saveGender()
        saveDateOfBirth()
        saveEmail()
    }
    
    private func savePhoneNumber() {
        UserDefaults.standard.set(phoneNumber, forKey: "patientPhoneNumber")
    }
    
    private func saveAddress() {
        UserDefaults.standard.set(address, forKey: "patientAddress")
    }
    
    private func saveBloodType() {
        UserDefaults.standard.set(selectedBloodType, forKey: "patientBloodType")
    }
    
    private func saveGender() {
        UserDefaults.standard.set(selectedGender, forKey: "patientGender")
    }
    
    private func saveDateOfBirth() {
        UserDefaults.standard.set(patientDateOfBirth, forKey: "patientDateOfBirth")
    }
    
    private func saveEmail() {
        UserDefaults.standard.set(patientEmail, forKey: "patientEmail")
    }
    
    // MARK: - Data Fetching
    
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
                        id: patientDocument.documentID,
                        name: data["name"] as? String ?? "Patient",
                        number: nil,
                        email: data["email"] as? String ?? "",
                        dateOfBirth: (data["dob"] as? Timestamp)?.dateValue(),
                        gender: data["gender"] as? String
                    )
                    
                    await MainActor.run {
                        updatePatientData(patientData)
                    }
                } else {
                    let patientData = try await PatientFirestoreService.shared.getOrCreatePatient(
                        userId: userId,
                        name: "Patient",
                        email: ""
                    )
                    
                    await MainActor.run {
                        updatePatientData(patientData)
                    }
                }
            } catch {
                print("Error fetching patient data: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func updatePatientData(_ patientData: Patient) {
        self.patient = patientData
        self.patientName = patientData.name
        self.patientEmail = patientData.email.isEmpty ? patientEmail : patientData.email
        self.patientDateOfBirth = patientData.dateOfBirth ?? patientDateOfBirth
        
        if selectedGender.isEmpty {
            self.selectedGender = patientData.gender ?? ""
        }
        
        isLoading = false
        
        if self.patientEmail.isEmpty {
            self.fetchEmailFromAppwrite(userId: patientData.id)
        }
    }
    
    private func fetchEmailFromAppwrite(userId: String) {
        Task {
            do {
                let db = Firestore.firestore()
                let userDocument = try await db.collection("users").document(userId).getDocument()
                
                if let userData = userDocument.data(), let email = userData["email"] as? String {
                    await MainActor.run {
                        self.patientEmail = email
                        saveEmail()
                    }
                }
            } catch {
                print("Error fetching email from Appwrite: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Subviews

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let placeholder: String
    let isEditable: Bool
    @Binding var text: String
    let onChange: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    
    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(theme.primary)
                .frame(width: 24, alignment: .center)
            
            if isEditable {
                TextField(placeholder, text: $text, onCommit: {
                    onChange?()
                })
                .font(.body)
                .foregroundColor(theme.text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            } else {
                Text(label.isEmpty ? placeholder : label)
                    .font(.body)
                    .foregroundColor(label.isEmpty ? theme.secondary : theme.text)
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

struct PickerRow: View {
    let icon: String
    let label: String
    @Binding var selection: String
    let options: [String]
    let isEditing: Bool
    let placeholder: String
    let onChange: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(theme.primary)
                .frame(width: 24, alignment: .center)
            
            if isEditing {
                Picker(selection: $selection) {
                    Text(placeholder).tag("")
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                } label: {
                    Text(label)
                        .foregroundColor(theme.text)
                }
                .pickerStyle(.menu)
                .onChange(of: selection, perform: { _ in onChange() })
            } else {
                Text(selection.isEmpty ? placeholder : selection)
                    .font(.body)
                    .foregroundColor(selection.isEmpty ? theme.secondary : theme.text)
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

struct DatePickerRow: View {
    let icon: String
    let label: String
    @Binding var date: Date?
    let isEditing: Bool
    let placeholder: String
    let onChange: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(theme.primary)
                .frame(width: 24, alignment: .center)
            
            if isEditing {
                DatePicker(
                    selection: Binding(
                        get: { date ?? Date() },
                        set: { newValue in
                            date = newValue
                            onChange()
                        }
                    ),
                    displayedComponents: [.date]
                ) {
                    Text(label)
                        .foregroundColor(theme.text)
                }
            } else {
                Text(date?.formatted(date: .abbreviated, time: .omitted) ?? placeholder)
                    .font(.body)
                    .foregroundColor(date == nil ? theme.secondary : theme.text)
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

struct PatientProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PatientProfileView()
                .environmentObject(AuthManager())
                .preferredColorScheme(.light)
        }
        
        NavigationStack {
            PatientProfileView()
                .environmentObject(AuthManager())
                .preferredColorScheme(.dark)
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
