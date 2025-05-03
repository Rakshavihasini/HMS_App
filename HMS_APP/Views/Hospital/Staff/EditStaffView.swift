import SwiftUI

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
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                    TextField("Role", text: $role)
                    
                    DatePicker("Date of Birth", 
                               selection: $dateOfBirth, 
                               in: dateOfBirthRange(),
                               displayedComponents: .date)
                    DatePicker("Date of Joining", selection: $joinDate, displayedComponents: .date)
                }
                
                Section(header: Text("Professional Details")) {
                    TextField("Education Qualification", text: $education)
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
            )
        }
    }
    
    private func saveChanges() {
        let updatedStaff = Staff(
            id: staff.id,
            name: name,
            email: email,
            dateOfBirth: dateOfBirth,
            joinDate: joinDate,
            educationalQualification: education.isEmpty ? nil : education,
            certificates: staff.certificates,
            staffRole: role.isEmpty ? nil : role
        )
        
        // Call save method in StaffService
        let staffService = StaffService()
        staffService.updateStaff(updatedStaff) { result in
            switch result {
            case .success:
                onSave(updatedStaff)
                dismiss()
            case .failure(let error):
                print("Error updating staff: \(error)")
            }
        }
    }
} 