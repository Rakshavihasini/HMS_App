import SwiftUI
import FirebaseFirestore

struct PatientsListView: View {
    @Environment(\.colorScheme) var colorScheme
//    @Binding var selectedTab: Int
    @StateObject private var patientDetails = PatientDetails()
    @StateObject private var appointmentManager = AppointmentManager()
    @State private var searchText = ""
    @State private var showPatientDetail = false
    @State private var selectedPatient: Patient?
    
    var body: some View {
        ZStack {
            // Background color
            (colorScheme == .dark ? Theme.dark.background : Theme.light.background)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading){
                        Text("Patients")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Text("Manage your patients")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    // Stats Circle
                    VStack(alignment: .center) {
                        Text("\(filteredPatients.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search Patients", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                )
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Patients List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPatients) { patient in
                            PatientCard(patient: patient)
                                .onTapGesture {
                                    selectedPatient = patient
                                    // Pre-fetch appointments for this patient
                                    Task {
                                        await appointmentManager.fetchAppointments(for: patient.id)
                                    }
                                    showPatientDetail = true
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $showPatientDetail) {
            if let patient = selectedPatient {
                PatientDetailView(patient: patient, appointmentManager: appointmentManager)
            }
        }
        .onAppear {
            patientDetails.fetchPatients()
        }
    }
    
    var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return patientDetails.patients
        } else {
            return patientDetails.patients.filter { patient in
                let searchQuery = searchText.lowercased()
                return patient.name.lowercased().contains(searchQuery) ||
                       (patient.age.map { String($0) }?.contains(searchQuery) ?? false) ||
                       (patient.gender?.lowercased().contains(searchQuery) ?? false)
            }
        }
    }
}

struct PatientCard: View {
    @Environment(\.colorScheme) var colorScheme
    let patient: Patient
    
    var initials: String {
        let components = patient.name.components(separatedBy: " ")
        if components.count > 1 {
            return String(components[0].prefix(1) + components[1].prefix(1))
        }
        return String(patient.name.prefix(2))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar Circle
            Circle()
                .fill(colorScheme == .dark ? Theme.dark.primary.opacity(0.2) : Theme.light.primary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(initials)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                HStack(spacing: 8) {
                    if let age = patient.age {
                        Text("\(age) years")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let gender = patient.gender {
                        Text(gender)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorScheme == .dark ? Theme.dark.primary.opacity(0.2) : Theme.light.primary.opacity(0.2))
                            .foregroundColor(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
}
