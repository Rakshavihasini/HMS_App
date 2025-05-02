import SwiftUI

struct AddStaffView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var staffService = StaffService()
    
    // State variables
    @State private var fullName: String = ""
    @State private var dateOfBirth: Date = {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 1985
        components.month = 1
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }()
    @State private var dateOfJoining: Date = Date()
    @State private var selectedDesignation: String = ""
    @State private var email: String = ""
    @State private var education: String = ""
    
    // UI State variables
    @State private var showingDateOfBirthPicker = false
    @State private var showingDateOfJoiningPicker = false
    @State private var showingDesignationPicker = false
    @State private var isShowingDocumentPicker = false
    @State private var uploadedCertificates: [URL] = []
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var animationProgress: CGFloat = 0

    let designations = ["Nurse", "Pharmacist", "Receptionist", "Counselor", "Lab Technician"]
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    personalInfoCard
                    
                    professionalDetailsCard
                    
                    certificatesSection
                    
                    saveButton
                        .padding()
                }
                .padding(.vertical)
                .animation(.spring(), value: animationProgress)
            }
            .navigationTitle("Add Staff Member")
            .navigationBarTitleDisplayMode(.inline)
            .background(currentTheme.background.edgesIgnoringSafeArea(.all))
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            // .toolbar {
            //     ToolbarItem(placement: .navigationBarLeading) {
            //         Button(action: { dismiss() }) {
            //             Image(systemName: "chevron.left")
            //             Text("Back")
            //         }
            //     }
            // }
            .onAppear {
                animateEntrance()
            }
        }
    }
    
    private func animateEntrance() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8, blendDuration: 0.5)) {
            animationProgress = 1
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "person.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(currentTheme.primary)
                .scaleEffect(1 + (1 - animationProgress) * 0.2)
            
            Text("Add New Staff Member")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(currentTheme.text)
                .opacity(animationProgress)
            
            Text("Please fill in the staff member's details")
                .font(.subheadline)
                .foregroundColor(currentTheme.text.opacity(0.7))
                .opacity(animationProgress)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(currentTheme.secondary.opacity(0.1))
        .offset(x: (1 - animationProgress) * 50)
    }
    
    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Personal Information")
            
            nameField
            dobField
            emailField
        }
        .padding()
        .background(currentTheme.card)
        .cornerRadius(16)
        .shadow(color: currentTheme.shadow.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(1 - (1 - animationProgress) * 0.1)
        .opacity(animationProgress)
        .offset(x: (1 - animationProgress) * -50)
    }
    
    private var professionalDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Professional Details")
            
            joiningDateField
            designationField
            educationField
        }
        .padding()
        .background(currentTheme.card)
        .cornerRadius(16)
        .shadow(color: currentTheme.shadow.opacity(0.1), radius: 5, x: 0, y: 2)
        .scaleEffect(1 - (1 - animationProgress) * 0.1)
        .opacity(animationProgress)
        .offset(x: (1 - animationProgress) * 50)
    }
    
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(currentTheme.primary)
            Spacer()
        }
    }
    
    private var saveButton: some View {
        Button(action: saveStaff) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(isSaving ? "Saving..." : "Save Staff Member")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? currentTheme.primary : .gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: currentTheme.shadow.opacity(0.2), radius: 5, x: 0, y: 2)
            .scaleEffect(isFormValid ? 1 : 0.95)
            .animation(.spring(), value: isFormValid)
        }
        .disabled(!isFormValid || isSaving)
        .opacity(animationProgress)
        .offset(y: (1 - animationProgress) * 50)
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && 
        !email.isEmpty && 
        !selectedDesignation.isEmpty && 
        !education.isEmpty && 
        !uploadedCertificates.isEmpty
    }
    
    private func saveStaff() {
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
    }
    
    private var nameField: some View {
        formField(
            label: "Name",
            icon: "person.fill",
            textField: TextField("Enter Full Name", text: $fullName)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        )
    }
    
    private var dobField: some View {
        datePickerField(
            label: "Date of Birth",
            icon: "calendar",
            date: $dateOfBirth,
            isShowing: $showingDateOfBirthPicker
        )
    }
    
    private var joiningDateField: some View {
        datePickerField(
            label: "Date of Joining",
            icon: "calendar",
            date: $dateOfJoining,
            isShowing: $showingDateOfJoiningPicker
        )
    }
    
    private var designationField: some View {
        designationPickerField()
    }
    
    private var emailField: some View {
        formField(
            label: "Email",
            icon: "envelope.fill",
            textField: TextField("email@example.com", text: $email)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        )
    }
    
    private var educationField: some View {
        formField(
            label: "Education Qualification",
            icon: "graduationcap.fill",
            textField: TextField("Enter highest qualification", text: $education)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        )
    }
    
    private var certificatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Certificates")
                .font(.headline)
                .foregroundColor(currentTheme.primary)

            certificateUploadView
            
            ForEach(uploadedCertificates, id: \.self) { url in
                certificateRowView(for: url)
            }
        }
    }
    
    private var certificateUploadView: some View {
        VStack {
            Image(systemName: "arrow.up.doc")
                .font(.title)
                .foregroundColor(currentTheme.primary)

            Text("Tap to upload certificates")
                .font(.subheadline)
                .foregroundColor(currentTheme.text)

            Text("PDF only, upto 10MB")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .gray.opacity(0.7) : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(currentTheme.secondary)
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(onDocumentsPicked: { urls in
                let pdfUrls = urls.filter { $0.pathExtension.lowercased() == "pdf" }
                uploadedCertificates.append(contentsOf: pdfUrls)
            })
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(currentTheme.border, lineWidth: 1)
        )
        .onTapGesture {
            isShowingDocumentPicker = true
        }
    }
    
    private func certificateRowView(for url: URL) -> some View {
        HStack {
            Image(systemName: "doc.pdf")
                .foregroundColor(.red)
            Text(url.lastPathComponent)
                .font(.caption)
                .foregroundColor(currentTheme.text)
            Spacer()
            Button(action: {
                uploadedCertificates.removeAll { $0 == url }
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
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
                DatePicker("", selection: date, 
                           in: datePickerRange(), 
                           displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .padding(.vertical)
            }
        }
    }
    
    private func datePickerRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        
        var dateComponents = DateComponents()
        dateComponents.year = 1965
        dateComponents.month = 1
        dateComponents.day = 1
        let startDate = calendar.date(from: dateComponents)!
        
        dateComponents.year = 2000
        dateComponents.month = 12
        dateComponents.day = 31
        let endDate = calendar.date(from: dateComponents)!
        
        return startDate...endDate
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
