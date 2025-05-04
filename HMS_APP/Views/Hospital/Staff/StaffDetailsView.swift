import SwiftUI

struct StaffDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var doctor: Doctor
    @State private var isPresentingEditView = false
    @State private var showRemoveConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Animation states
    @State private var profileOpacity = 0.0
    @State private var profileOffset = CGFloat(20)
    @State private var infoOpacity = 0.0
    @State private var buttonScale = 0.95
    @State private var isLoaded = false
    
    // Responsive sizing
    @Environment(\.horizontalSizeClass) var sizeClass
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    private var theme: Theme {
        colorScheme == .dark ? .dark : .light
    }
    
    private var isCompact: Bool {
        return sizeClass == .compact
    }
    
    init(doctor: Doctor) {
        self._doctor = State(initialValue: doctor)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not Specified" }
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView(width: geometry.size.width)
                
                // Content
                ScrollView {
                    VStack(spacing: isCompact ? 16 : 24) {
                        // Profile
                        profileView
                            .padding(.top, isCompact ? 16 : 24)
                            .opacity(profileOpacity)
                            .offset(y: profileOffset)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    profileOpacity = 1.0
                                    profileOffset = 0
                                }
                            }
                        
                        // Personal Info
                        personalInfoView(width: geometry.size.width)
                            .opacity(infoOpacity)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                                    infoOpacity = 1.0
                                }
                            }
                        
                        // Buttons
                        actionButtonsView(width: geometry.size.width)
                            .scaleEffect(buttonScale)
                            .onAppear {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    buttonScale = 1.0
                                }
                            }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    .background(theme.background)
                }
                .background(theme.background)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isPresentingEditView) {
                EditDoctorView(doctor: doctor) { updatedDoctor in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        doctor = updatedDoctor
                    }
                }
            }
            .alert(isPresented: $showRemoveConfirmation) {
                Alert(
                    title: Text("Confirm Removal"),
                    message: Text("Are you sure you want to remove \(doctor.name)? This action cannot be undone."),
                    primaryButton: .destructive(Text("Remove")) {
                        let doctorService = DoctorService()
                        doctorService.deleteDoctor(doctor: doctor) { success in
                            if success {
                                withAnimation {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
    
    // MARK: - Component Views
    
    private func headerView(width: CGFloat) -> some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                        .contentShape(Circle())
                }
                
                Spacer()
                
                Text("Staff Details")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Invisible element for balanced layout
                Image(systemName: "chevron.left")
                    .foregroundColor(.clear)
                    .imageScale(.large)
                    .padding(8)
            }
            .padding(.horizontal, isCompact ? 16 : 24)
            .padding(.top, 50)
        }
        .frame(width: width)
        .frame(height: isCompact ? 120 : 140)
        .background(
            theme.primary
                .shadow(color: theme.shadow, radius: 4, y: 2)
        )
    }
    
    private var profileView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: isCompact ? 80 : 100, height: isCompact ? 80 : 100)
                .foregroundColor(theme.primary)
                .shadow(color: theme.shadow, radius: 2)
                .transition(.scale.combined(with: .opacity))
            
            Text(doctor.name)
                .font(.system(size: isCompact ? 20 : 24, weight: .bold))
                .foregroundColor(theme.primary)
        }
        .padding(.bottom, 8)
    }
    
    private func personalInfoView(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? 12 : 16) {
            Text("Personal Information")
                .font(.headline)
                .foregroundColor(theme.primary)
                .padding(.horizontal, isCompact ? 16 : 24)
            
            VStack(spacing: isCompact ? 16 : 20) {
                StaffInfoRow(icon: "calendar", label: "Date of Birth", value: formatDate(doctor.dateOfBirth), theme: theme)
                Divider().background(theme.border)
                StaffInfoRow(icon: "envelope", label: "Email", value: doctor.email, theme: theme)
                Divider().background(theme.border)
                StaffInfoRow(icon: "person", label: "Gender", value: doctor.gender ?? "Not Specified", theme: theme)
                Divider().background(theme.border)
                StaffInfoRow(icon: "graduationcap", label: "License No", value: doctor.licenseRegNo ?? "Not Specified", theme: theme)
                Divider().background(theme.border)
                StaffInfoRow(icon: "stethoscope", label: "State Medical Council", value: doctor.smc ?? "Not Specified", theme: theme)
                Divider().background(theme.border)
                StaffInfoRow(icon: "calendar", label: "Year of Registration", value: doctor.yearOfRegistration?.description ?? "Not Specified", theme: theme)
            }
            .padding(.vertical, isCompact ? 16 : 20)
            .padding(.horizontal, isCompact ? 16 : 20)
            .background(theme.card)
            .cornerRadius(15)
            .shadow(color: theme.shadow, radius: 3, y: 2)
        }
        .frame(width: width - (isCompact ? 32 : 48))
    }
    
    private func actionButtonsView(width: CGFloat) -> some View {
        HStack(spacing: isCompact ? 12 : 20) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresentingEditView = true
                }
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Update")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompact ? 14 : 16)
                .background(theme.primary)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: theme.shadow, radius: 2)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showRemoveConfirmation = true
                }
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Remove")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompact ? 14 : 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red, lineWidth: 1.5)
                )
                .foregroundColor(.red)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, isCompact ? 16 : 24)
        .padding(.vertical, isCompact ? 16 : 20)
    }
}
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
