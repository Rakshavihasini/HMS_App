import SwiftUI
import FirebaseFirestore

struct EditStaffView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var staff: Staff
    @State private var name: String
    @State private var email: String
    @State private var role: String
    @State private var education: String
    @State private var dateOfBirth: Date
    @State private var joinDate: Date
    @State private var isLoading = false
    
    var onSave: (Staff) -> Void
    
    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    init(staff: Staff, onSave: @escaping (Staff) -> Void) {
        self._staff = State(initialValue: staff)
        self._name = State(initialValue: staff.name)
        self._email = State(initialValue: staff.email)
        self._role = State(initialValue: staff.staffRole ?? "")
        self._education = State(initialValue: staff.educationalQualification ?? "")
        self._dateOfBirth = State(initialValue: staff.dateOfBirth ?? Date())
        self._joinDate = State(initialValue: staff.joinDate ?? Date())
        self.onSave = onSave
    }
    
    private func dateOfBirthRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        
        var startComponents = DateComponents()
        startComponents.year = 1965
        startComponents.month = 1
        startComponents.day = 1
        let startDate = calendar.date(from: startComponents)!
        
        var endComponents = DateComponents()
        endComponents.year = 2000
        endComponents.month = 12
        endComponents.day = 31
        let endDate = calendar.date(from: endComponents)!
        
        return startDate...endDate
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                        TextField("Role", text: $role)
                            .foregroundColor(theme.text)
                        
                        DatePicker("Date of Birth", 
                                selection: $dateOfBirth, 
                                in: dateOfBirthRange(),
                                displayedComponents: .date)
                            .foregroundColor(theme.text)
                        DatePicker("Date of Joining", selection: $joinDate, displayedComponents: .date)
                            .foregroundColor(theme.text)
                    }
                    
                    Section(header: 
                        Text("Professional Details")
                            .font(.headline)
                            .foregroundColor(theme.primary)
                            .padding(.top, 5)
                    ) {
                        TextField("Education Qualification", text: $education)
                            .foregroundColor(theme.text)
                    }
                }
                .navigationTitle("Edit Staff Details")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        dismiss()
                    },
                    trailing: Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                )
                
                if isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        Text("Loading Staff Data...")
                            .foregroundColor(.white)
                            .bold()
                    }
                    .padding(20)
                    .background(theme.card)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                }
            }
            .accentColor(theme.primary)
            .onAppear {
                fetchStaffDetails()
            }
        }
    }
    
    private func fetchStaffDetails() {
        isLoading = true
        let db = Firestore.firestore()
        
        print("DEBUG: Fetching staff details for ID: \(staff.id)")
        
        db.collection("hms4_staff")
            .document(staff.id)
            .getDocument { document, error in
                isLoading = false
                
                if let error = error {
                    print("Error fetching staff details: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("Staff document doesn't exist")
                    return
                }
                
                // Print all keys to debug
                print("DEBUG: Staff document data keys: \(Array(data.keys))")
                
                // Extract staff details
                if let staffName = data["name"] as? String {
                    self.name = staffName
                }
                
                if let staffEmail = data["email"] as? String {
                    self.email = staffEmail
                }
                
                if let staffRole = data["staffRole"] as? String {
                    self.role = staffRole
                }
                
                if let qualification = data["educationalQualification"] as? String {
                    self.education = qualification
                }
                
                // Handle date fields
                if let dobTimestamp = data["dateOfBirth"] as? Timestamp {
                    self.dateOfBirth = dobTimestamp.dateValue()
                }
                
                if let joinTimestamp = data["joinDate"] as? Timestamp {
                    self.joinDate = joinTimestamp.dateValue()
                }
                
                print("DEBUG: Successfully loaded staff details")
            }
    }
    
    private func saveChanges() {
        isLoading = true
        let db = Firestore.firestore()
        
        // Create staff data matching existing structure in Firebase
        var staffData: [String: Any] = [
            "name": name,
            "email": email,
            "staffRole": role.isEmpty ? NSNull() : role,
            "educationalQualification": education.isEmpty ? NSNull() : education,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Handle date fields
        if let dobDate = dateOfBirth as Date? {
            staffData["dateOfBirth"] = Timestamp(date: dobDate)
        }
        
        if let joinDate = joinDate as Date? {
            staffData["joinDate"] = Timestamp(date: joinDate)
        }
        
        // Preserve certificates if they exist
        if let certs = staff.certificates, !certs.isEmpty {
            staffData["certificates"] = certs
        }
        
        // Update the document in Firebase
        db.collection("hms4_staff").document(staff.id).updateData(staffData) { error in
            isLoading = false
            
            if let error = error {
                print("Error updating staff: \(error.localizedDescription)")
            } else {
                print("Staff information updated successfully")
                
                // Create updated Staff object with the app's model structure
                let updatedStaff = Staff(
                    id: self.staff.id,
                    name: self.name,
                    email: self.email,
                    dateOfBirth: self.dateOfBirth,
                    joinDate: self.joinDate,
                    educationalQualification: self.education.isEmpty ? nil : self.education,
                    certificates: self.staff.certificates,
                    staffRole: self.role.isEmpty ? nil : self.role,
                    status: self.staff.status
                )
                
                // Call the onSave callback with updated staff
                self.onSave(updatedStaff)
                self.dismiss()
            }
        }
    }
} 