import SwiftUI
import FirebaseFirestore

struct PatientInfoView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var patient: Patient?
    @State private var isLoading = true
    @State private var isEditing = false
    
    @State private var name = ""
    @State private var email = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender = "Male"
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else if let patient = patient {
                PatientInfoCard(patient: patient, isEditing: $isEditing, name: $name, email: $email, dateOfBirth: $dateOfBirth, gender: $gender)
                
                Spacer()
                
                if isEditing {
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.medicareBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: cancelEditing) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.medicareRed)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                } else {
                    Button(action: { isEditing = true }) {
                        Text("Edit Profile")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.medicareBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("No patient information found")
                    .font(.headline)
                    .padding()
                
                Button(action: setupPatientProfile) {
                    Text("Setup Profile")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.medicareBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Patient Profile")
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
                let email = "user@gmail.com"
                let patientData = try await PatientFirestoreService.shared.getOrCreatePatient(
                    userId: userId,
                    name: "Patient",
                    email: email,
                    gender: "Male"
                )
                
                await MainActor.run {
                    self.patient = patientData
                    self.name = patientData.name
                    self.email = patientData.email
                    self.dateOfBirth = patientData.dateOfBirth ?? Date()
                    self.gender = patientData.gender ?? "Male"
                    self.isLoading = false
                }
            } catch {
                print("Error fetching patient data: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        let updatedFields: [String: Any] = [
            "name": name,
            "email": email,
            "dob": dateOfBirth,
            "gender": gender,
            "updatedAt": FirebaseFirestore.FieldValue.serverTimestamp()
        ]
        
        Task {
            do {
                try await PatientFirestoreService.shared.updatePatient(userId: userId, updatedFields: updatedFields)
                
                await MainActor.run {
                    if let currentPatient = patient {
                        // Create a new Patient instance with updated values
                        let updatedPatient = Patient(
                            id: currentPatient.id,
                            name: name,
                            number: currentPatient.number,
                            email: email,
                            dateOfBirth: dateOfBirth,
                            gender: gender
                        )
                        self.patient = updatedPatient
                        self.isEditing = false
                    }
                }
            } catch {
                print("Error updating patient data: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupPatientProfile() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else { return }
        
        let newPatient = Patient(
            id: UUID().uuidString,
            name: name.isEmpty ? "Patient" : name,
            email: email.isEmpty ? "user@gmail.com" : email,
            dateOfBirth: dateOfBirth,
            gender: gender
        )
        
        Task {
            do {
                try await PatientFirestoreService.shared.addPatient(userId: userId, patient: newPatient)
                
                await MainActor.run {
                    self.patient = newPatient
                }
            } catch {
                print("Error creating patient profile: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelEditing() {
        if let patient = patient {
            name = patient.name
            email = patient.email
            dateOfBirth = patient.dateOfBirth ?? Date()
            gender = patient.gender ?? "Male"
        }
        isEditing = false
    }
}

struct PatientInfoCard: View {
    let patient: Patient
    @Binding var isEditing: Bool
    @Binding var name: String
    @Binding var email: String
    @Binding var dateOfBirth: Date
    @Binding var gender: String
    
    private let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditing {
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Date of Birth:")
                    DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                        .labelsHidden()
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Gender:")
                    Picker("Gender", selection: $gender) {
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
            } else {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.medicareBlue)
                    
                    VStack(alignment: .leading) {
                        Text(patient.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let age = patient.age {
                            Text("\(age) years • \(patient.gender ?? "Not specified")")
                                .foregroundColor(.gray)
                        } else {
                            Text(patient.gender ?? "Not specified")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(patient.email)
                            .font(.body)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                if let dob = patient.dateOfBirth {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Date of Birth")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(dob.formatted(date: .abbreviated, time: .omitted))
                                .font(.body)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding()
    }
}

#Preview {
    PatientInfoView()
        .environmentObject(AuthManager())
}
