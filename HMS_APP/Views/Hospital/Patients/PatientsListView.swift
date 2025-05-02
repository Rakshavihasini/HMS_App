import SwiftUI
import FirebaseFirestore

struct PatientsListView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedTab: Int
    @StateObject private var patientDetails = PatientDetails()
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
                    Text("Patients")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                
                // Patients List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPatients) { patient in
                            PatientCard(patient: patient)
                                .onTapGesture {
                                    selectedPatient = patient
                                    showPatientDetail = true
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationDestination(isPresented: $showPatientDetail) {
            if let patient = selectedPatient {
                PatientDetailView(patient: patient)
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
                       patient.email.lowercased().contains(searchQuery) ||
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
                
                Text(patient.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    if let age = patient.age {
                        Text("\(age) years")
                            .font(.caption)
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
