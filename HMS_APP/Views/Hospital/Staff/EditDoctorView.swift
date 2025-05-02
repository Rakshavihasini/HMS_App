import SwiftUI

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
    
    var onSave: (Doctor) -> Void
    
    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    init(doctor: Doctor, onSave: @escaping (Doctor) -> Void) {
        self._doctor = State(initialValue: doctor)
        self._name = State(initialValue: doctor.name)
        self._email = State(initialValue: doctor.email)
        self._licenseNo = State(initialValue: doctor.licenseRegNo ?? "")
        self._smc = State(initialValue: doctor.smc ?? "")
        self._gender = State(initialValue: doctor.gender ?? "")
        self._dateOfBirth = State(initialValue: doctor.dateOfBirth ?? Date())
        self._yearOfRegistration = State(initialValue: doctor.yearOfRegistration ?? Calendar.current.component(.year, from: Date()))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                    TextField("License Number", text: $licenseNo)
                    TextField("State Medical Council", text: $smc)
                    
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    
                    Stepper("Year of Registration: \(yearOfRegistration)", 
                            value: $yearOfRegistration, 
                            in: 1950...Calendar.current.component(.year, from: Date()))
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
            )
        }
    }
    
    private func saveChanges() {
        let updatedDoctor = Doctor(
            id: doctor.id,
            name: name,
            number: doctor.number,
            email: email,
            speciality: doctor.speciality,
            licenseRegNo: licenseNo.isEmpty ? nil : licenseNo,
            smc: smc.isEmpty ? nil : smc,
            gender: gender.isEmpty ? nil : gender,
            dateOfBirth: dateOfBirth,
            yearOfRegistration: yearOfRegistration,
            schedule: doctor.schedule
        )
        
        // Call save method in DoctorService
        let doctorService = DoctorService()
        doctorService.addDoctor(updatedDoctor) { result in
            switch result {
            case .success:
                onSave(updatedDoctor)
                dismiss()
            case .failure(let error):
                print("Error updating doctor: \(error)")
            }
        }
    }
} 
