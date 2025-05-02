import SwiftUI

struct AddStaffView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var staffService = StaffService()
    @State private var fullName: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var dateOfJoining: Date = Date()
    @State private var selectedDesignation: String = ""
    @State private var email: String = ""
    @State private var education: String = ""
    @State private var showingDateOfBirthPicker = false
    @State private var showingDateOfJoiningPicker = false
    @State private var showingDesignationPicker = false
    @State private var isShowingDocumentPicker = false
    @State private var uploadedCertificates: [URL] = []
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    let designations = ["Nurse", "Doctor", "Pharmacist", "Receptionist", "Counselor", "Lab Technician"]
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                formField(
                    label: "Name",
                    icon: "person.fill",
                    textField: TextField("Enter Full Name", text: $fullName)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                )

                datePickerField(
                    label: "Date of Birth",
                    icon: "calendar",
                    date: $dateOfBirth,
                    isShowing: $showingDateOfBirthPicker
                )

                datePickerField(
                    label: "Date of Joining",
                    icon: "calendar",
                    date: $dateOfJoining,
                    isShowing: $showingDateOfJoiningPicker
                )

                designationPickerField()

                formField(
                    label: "Email",
                    icon: "envelope.fill",
                    textField: TextField("email@example.com", text: $email)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                )

                formField(
                    label: "Education Qualification",
                    icon: "graduationcap.fill",
                    textField: TextField("Enter highest qualification", text: $education)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Certificates")
                        .font(.headline)
                        .foregroundColor(currentTheme.primary)

                    VStack {
                        Image(systemName: "arrow.up.doc")
                            .font(.title)
                            .foregroundColor(currentTheme.primary)

                        Text("Tap to upload certificates")
                            .font(.subheadline)
                            .foregroundColor(currentTheme.text)

                        Text("PDF, PNG, JPG upto 10MB")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .gray.opacity(0.7) : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentTheme.secondary)
                    .sheet(isPresented: $isShowingDocumentPicker) {
                        DocumentPicker { urls in
                            uploadedCertificates.append(contentsOf: urls)
                        }
                    }
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(currentTheme.border, lineWidth: 1)
                    )
                    .onTapGesture {
                        isShowingDocumentPicker = true
                    }
                    
                    ForEach(uploadedCertificates, id: \.self) { url in
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(currentTheme.text)
                    }
                }

                Button(action: {
                    isSaving = true
                    let staff = Staff(
                        id: UUID().uuidString,
                        name: fullName,
                        email: email,
                        dateOfBirth: dateOfBirth,
                        joinDate: dateOfJoining,
                        educationalQualification: education,
                        certificates: [],
                        staffRole: selectedDesignation
                    )
                    
                    staffService.addStaff(staff, certificateFiles: uploadedCertificates) { result in
                        isSaving = false
                        switch result {
                        case .success:
                            dismiss()
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                            showErrorAlert = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text(isSaving ? "Saving..." : "Add Staff Member")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(isSaving || fullName.isEmpty || selectedDesignation.isEmpty || education.isEmpty)
                }
                .padding(.vertical)
            }
            .padding()
        }
        .navigationTitle("Add Staff Member")
        .background(currentTheme.background.edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    @ViewBuilder
    func formField(label: String, icon: String, textField: some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(currentTheme.primary)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(colorScheme == .dark ? .gray.opacity(0.7) : .gray)
                textField
            }
            .padding()
            .background(currentTheme.card)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(currentTheme.border, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    func datePickerField(label: String, icon: String, date: Binding<Date>, isShowing: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(currentTheme.primary)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(colorScheme == .dark ? .gray.opacity(0.7) : .gray)
                Text(formattedDate(date.wrappedValue))
                    .foregroundColor(formattedDate(date.wrappedValue) == "dd/mm/yyyy" ?
                                     (colorScheme == .dark ? .gray.opacity(0.7) : .gray) :
                                     (colorScheme == .dark ? .white : .primary))
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isShowing.wrappedValue.toggle()
            }
            .padding()
            .background(currentTheme.card)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(currentTheme.border, lineWidth: 1)
            )

            if isShowing.wrappedValue {
                DatePicker("", selection: date, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding(.vertical)
            }
        }
    }

    @ViewBuilder
    func designationPickerField() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Designation")
                .font(.headline)
                .foregroundColor(currentTheme.primary)

            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(colorScheme == .dark ? .gray.opacity(0.7) : .gray)
                Text(selectedDesignation.isEmpty ? "Select Designation" : selectedDesignation)
                    .foregroundColor(selectedDesignation.isEmpty ?
                                    (colorScheme == .dark ? .gray.opacity(0.7) : .gray) :
                                    (colorScheme == .dark ? .white : .primary))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(colorScheme == .dark ? .gray.opacity(0.7) : .gray)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingDesignationPicker.toggle()
            }
            .padding()
            .background(currentTheme.card)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(currentTheme.border, lineWidth: 1)
            )

            if showingDesignationPicker {
                VStack(alignment: .leading) {
                    ForEach(designations, id: \.self) { designation in
                        Button(action: {
                            selectedDesignation = designation
                            showingDesignationPicker = false
                        }) {
                            Text(designation)
                                .padding(.vertical, 8)
                                .foregroundColor(currentTheme.text)
                        }
                        Divider()
                    }
                }
                .padding()
                .background(currentTheme.card)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(currentTheme.border, lineWidth: 1)
                )
            }
        }
    }
}
