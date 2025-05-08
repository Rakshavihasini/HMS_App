import SwiftUI
import FirebaseFirestore


struct EditDoctorView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var doctor: Doctor
    @State private var name: String
    @State private var email: String
    @State private var licenseNo: String
    @State private var smc: String
    @State private var gender: String
    @State private var dateOfBirth: Date
    @State private var yearOfRegistration: Int
    @State private var isLoading = false
    
    var onSave: (Doctor) -> Void
    
    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    // Add date range for DOB picker
    private var dobDateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let currentYear = 2005 // Max year allowed
        
        // Start date (minimum birth year)
        var startComponents = DateComponents()
        startComponents.year = 1950
        startComponents.month = 1
        startComponents.day = 1
        let startDate = calendar.date(from: startComponents)!
        
        // End date (maximum birth year - 2005)
        var endComponents = DateComponents()
        endComponents.year = currentYear
        endComponents.month = 12
        endComponents.day = 31
        let endDate = calendar.date(from: endComponents)!
        
        return startDate...endDate
    }
    
    init(doctor: Doctor, onSave: @escaping (Doctor) -> Void) {
        self._doctor = State(initialValue: doctor)
        self._name = State(initialValue: doctor.name)
        self._email = State(initialValue: doctor.email)
        self._licenseNo = State(initialValue: doctor.licenseRegNo ?? "")
        self._smc = State(initialValue: doctor.smc ?? "")
        self._gender = State(initialValue: doctor.gender ?? "")
        
        // Set default date to 2005 if no date or date is after 2005
        let defaultDate = Calendar.current.date(from: DateComponents(year: 2005, month: 1, day: 1)) ?? Date()
        if let dob = doctor.dateOfBirth {
            let calendar = Calendar.current
            let dobYear = calendar.component(.year, from: dob)
            if dobYear > 2005 {
                self._dateOfBirth = State(initialValue: defaultDate)
            } else {
                self._dateOfBirth = State(initialValue: dob)
            }
        } else {
            self._dateOfBirth = State(initialValue: defaultDate)
        }
        
        self._yearOfRegistration = State(initialValue: doctor.yearOfRegistration ?? Calendar.current.component(.year, from: Date()))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: 
                    Text("Personal Information")
                        .font(.headline)
                        .foregroundColor(theme.primary)
                        .padding(.top, 5)
                ) {
                    TextField("Full Name", text: $name)
                        .foregroundColor(theme.text)
                    TextField("Email", text: $email)
                        .foregroundColor(theme.text)
                    
                    if isLoading {
                        HStack {
                            Text("Registration Number")
                                .foregroundColor(theme.text)
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Registration Number")
                                    .foregroundColor(theme.text)
                                Spacer()
                            }
                            Text(licenseNo.isEmpty ? "Not available" : licenseNo)
                                .foregroundColor(licenseNo.isEmpty ? theme.text.opacity(0.5) : theme.primary)
                                .font(.system(size: 15, weight: .medium))
                                .padding(.top, 2)
                        }
                    }
                    
                    if isLoading {
                        HStack {
                            Text("Medical Council")
                                .foregroundColor(theme.text)
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Medical Council")
                                    .foregroundColor(theme.text)
                                Spacer()
                            }
                            Text(smc.isEmpty ? "Not available" : smc)
                                .foregroundColor(smc.isEmpty ? theme.text.opacity(0.5) : theme.primary)
                                .font(.system(size: 15, weight: .medium))
                                .padding(.top, 2)
                        }
                    }
                    
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .foregroundColor(theme.text)
                    
                    DatePicker("Date of Birth", 
                               selection: $dateOfBirth, 
                               in: dobDateRange,
                               displayedComponents: .date)
                        .foregroundColor(theme.text)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Year of Registration")
                                .foregroundColor(theme.text)
                            Spacer()
                        }
                        Text(String(yearOfRegistration))
                            .foregroundColor(theme.primary)
                            .font(.system(size: 15, weight: .medium))
                            .padding(.top, 2)
                    }
                }
            }
            .navigationTitle("Edit Doctor Details")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
                .fontWeight(.semibold)
            )
        }
        .accentColor(theme.primary)
        .onAppear {
            fetchDoctorDetails()
        }
    }
    
    private func fetchDoctorDetails() {
        isLoading = true
        let db = Firestore.firestore()
        
        print("DEBUG: Fetching doctor details for ID: \(doctor.id)")
        
        db.collection("hms4_doctors")
            .document(doctor.id)
            .getDocument { document, error in
                isLoading = false
                
                if let error = error {
                    print("Error fetching doctor license: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("Doctor document doesn't exist")
                    return
                }
                
                // Print all keys to debug
                print("DEBUG: Document data keys: \(Array(data.keys))")
                
                // Check for license details as in DoctorManager
                if let licenseDetails = data["licenseDetails"] as? [String: Any] {
                    print("DEBUG: License details found")
                    
                    // Map from Firebase structure to Doctor model properties
                    if let registrationNumber = licenseDetails["registrationNumber"] as? String {
                        self.licenseNo = registrationNumber
                        print("DEBUG: Found registration number: \(registrationNumber)")
                    }
                    
                    if let councilName = licenseDetails["councilName"] as? String {
                        self.smc = councilName
                        print("DEBUG: Found council name: \(councilName)")
                    }
                    
                    if let yearOfReg = licenseDetails["yearOfRegistration"] as? String,
                       let year = Int(yearOfReg) {
                        self.yearOfRegistration = year
                        print("DEBUG: Found year of registration: \(year)")
                    }
                } else {
                    // Fallback to direct properties as defined in the model
                    if let regNo = data["licenseRegNo"] as? String {
                        self.licenseNo = regNo
                    }
                    
                    if let stateMedicalCouncil = data["smc"] as? String {
                        self.smc = stateMedicalCouncil
                    }
                    
                    if let year = data["yearOfRegistration"] as? Int {
                        self.yearOfRegistration = year
                    }
                }
            }
    }
    
    private func saveChanges() {
        let db = Firestore.firestore()
        
        // Create document data matching existing structure in Firebase
        var doctorData: [String: Any] = [
            "name": name,
            "email": email,
            "speciality": doctor.speciality
        ]
        
        // Add gender if provided
        if !gender.isEmpty {
            doctorData["gender"] = gender
        }
        
        // Handle date of birth
        if let dobDate = dateOfBirth as Date? {
            doctorData["dob"] = Timestamp(date: dobDate)
        }
        
        // Create licenseDetails object as seen in Firebase
        var licenseDetails: [String: Any] = [:]
        
        // Add registration number
        if !licenseNo.isEmpty {
            licenseDetails["registrationNumber"] = licenseNo
        }
        
        // Add medical council
        if !smc.isEmpty {
            licenseDetails["councilName"] = smc
        }
        
        // Add year of registration as string (as seen in Firebase)
        licenseDetails["yearOfRegistration"] = String(yearOfRegistration)
        
        // Maintain verification status if it exists
        licenseDetails["verificationStatus"] = "Verified"
        
        // Add license details to main document
        doctorData["licenseDetails"] = licenseDetails
        
        // For compatibility with the model, also set direct properties
        if !licenseNo.isEmpty {
            doctorData["licenseRegNo"] = licenseNo
        }
        
        if !smc.isEmpty {
            doctorData["smc"] = smc
        }
        
        doctorData["yearOfRegistration"] = yearOfRegistration
        
        // Update the document in Firebase
        db.collection("hms4_doctors").document(doctor.id).updateData(doctorData) { error in
            if let error = error {
                print("Error updating doctor: \(error.localizedDescription)")
            } else {
                print("Doctor information updated successfully")
                
                // Create Doctor object with the app's model structure
                let updatedDoctor = Doctor(
                    id: self.doctor.id,
                    name: self.name,
                    number: self.doctor.number,
                    email: self.email,
                    speciality: self.doctor.speciality,
                    licenseRegNo: self.licenseNo,
                    smc: self.smc,
                    gender: self.gender.isEmpty ? nil : self.gender,
                    dateOfBirth: self.dateOfBirth,
                    yearOfRegistration: self.yearOfRegistration,
                    schedule: self.doctor.schedule
                )
                
                // Call the onSave callback with updated doctor
                self.onSave(updatedDoctor)
                self.dismiss()
            }
        }
    }
} 
