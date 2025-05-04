import SwiftUI

struct GenericStaffDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var staff: Staff
    @State private var isPresentingEditView = false
    @State private var showRemoveConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }

    init(staff: Staff) {
        self._staff = State(initialValue: staff)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not Specified" }
        return dateFormatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    Spacer()
                    
                    Text("Staff Details")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.trailing, 20)
                .padding(.top, 50)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(theme.primary)

            ScrollView {
                VStack(spacing: 16) {
                    // Profile
                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(theme.primary)
                        Text(staff.name)
                            .font(.headline)
                            .foregroundColor(theme.primary)
                        Text(staff.staffRole ?? "Staff")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)

                    // Personal Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personal Information")
                            .font(.headline)
                            .foregroundColor(theme.primary)
                        VStack(spacing: 16) {
                            StaffInfoRow(icon: "calendar", label: "Date of Birth", value: formatDate(staff.dateOfBirth), theme: theme)
                            Divider().background(theme.border)
                            StaffInfoRow(icon: "calendar", label: "Date of Joining", value: formatDate(staff.joinDate), theme: theme)
                            Divider().background(theme.border)
                            StaffInfoRow(icon: "envelope", label: "Email", value: staff.email, theme: theme)
                        }
                        .padding()
                        .background(theme.card)
                        .cornerRadius(15)
                        .shadow(color: theme.shadow, radius: 2)
                    }
                    .padding(.horizontal, 16)

                    // Qualifications
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Professional Details")
                            .font(.headline)
                            .foregroundColor(theme.primary)
                        VStack(spacing: 16) {
                            StaffInfoRow(icon: "graduationcap", label: "Education Qualification", value: staff.educationalQualification ?? "Not Specified", theme: theme)
                            Divider().background(theme.border)
                            
                            if let certificates = staff.certificates, !certificates.isEmpty {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(theme.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Certificates")
                                            .font(.caption)
                                            .foregroundColor(theme.secondary)
                                        Text(certificates.joined(separator: ", "))
                                            .font(.body)
                                            .foregroundColor(theme.text)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(theme.card)
                        .cornerRadius(15)
                        .shadow(color: theme.shadow, radius: 2)
                    }
                    .padding(.horizontal, 16)

                    // Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            isPresentingEditView = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.pencil")
                                Text("Update")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }

                        Button(action: {
                            showRemoveConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1.5)
                            )
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
                .padding(.top)
                .background(theme.background)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isPresentingEditView) {
            EditStaffView(staff: staff) { updatedStaff in
                staff = updatedStaff
            }
        }
        .alert(isPresented: $showRemoveConfirmation) {
            Alert(
                title: Text("Confirm Removal"),
                message: Text("Are you sure you want to remove \(staff.name)? This action cannot be undone."),
                primaryButton: .destructive(Text("Remove")) {
                    let staffService = StaffService()
                    staffService.deleteStaff(staff: staff) { success in
                        if success {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .edgesIgnoringSafeArea(.top)
    }
} 
