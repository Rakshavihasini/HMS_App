import SwiftUI
import FirebaseFirestore

struct DoctorPatientsListView: View {
    // Environment and state variables
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = DoctorPatientsViewModel()
    @State private var searchText = ""
    @State private var showPatientDetail = false
    @State private var selectedPatient: Patient?
    
    // Doctor ID to filter patients by
    let doctorId: String
    
    var body: some View {
        ZStack {
            // Background color
            (colorScheme == .dark ? Theme.dark.background : Theme.light.background)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Your Patients")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search Patients...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                )
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading patients...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if viewModel.patients.isEmpty {
                    Spacer()
                    Text("No patients found for this doctor")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    // Patients List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPatients) { patient in
                                PatientCard(patient: patient)
                                    .onTapGesture {
                                        selectedPatient = patient
                                        // Pre-fetch appointments for this patient
                                        Task {
                                            await viewModel.appointmentManager.fetchAppointments(for: patient.id)
                                        }
                                        showPatientDetail = true
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $showPatientDetail) {
            if let patient = selectedPatient {
                PatientDetailView(patient: patient, appointmentManager: viewModel.appointmentManager)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchPatientsForDoctor(doctorId: doctorId)
            }
        }
    }
    
    var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return viewModel.patients
        } else {
            return viewModel.patients.filter { patient in
                let searchQuery = searchText.lowercased()
                return patient.name.lowercased().contains(searchQuery) ||
                       (patient.age.map { String($0) }?.contains(searchQuery) ?? false) ||
                       (patient.gender?.lowercased().contains(searchQuery) ?? false)
            }
        }
    }
}

// ViewModel to handle the business logic
class DoctorPatientsViewModel: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    
    let appointmentManager = AppointmentManager()
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    @MainActor
    func fetchPatientsForDoctor(doctorId: String) async {
        isLoading = true
        error = nil
        
        do {
            // 1. Fetch all appointments for this doctor
            let appointmentsSnapshot = try await db.collection("\(dbName)_appointments")
                .whereField("docId", isEqualTo: doctorId)
                .getDocuments()
            
            // 2. Extract unique patient IDs from appointments
            var patientIds = Set<String>()
            for document in appointmentsSnapshot.documents {
                if let patientId = document.data()["patId"] as? String {
                    patientIds.insert(patientId)
                }
            }
            
            if patientIds.isEmpty {
                self.patients = []
                self.isLoading = false
                return
            }
            
            // 3. Fetch patient details for each patient ID
            var patientsList: [Patient] = []
            
            for patientId in patientIds {
                let patientDoc = try await db.collection("\(dbName)_patients")
                    .document(patientId)
                    .getDocument()
                
                if let data = patientDoc.data() {
                    let patient = Patient(
                        id: patientDoc.documentID,
                        name: data["name"] as? String ?? "",
                        number: data["number"] as? Int,
                        email: data["email"] as? String ?? "",
                        dateOfBirth: (data["dob"] as? Timestamp)?.dateValue(),
                        gender: data["gender"] as? String
                    )
                    patientsList.append(patient)
                }
            }
            
            // 4. Sort patients by name
            patientsList.sort { $0.name < $1.name }
            
            self.patients = patientsList
            self.isLoading = false
            
        } catch {
            self.error = "Error fetching patients: \(error.localizedDescription)"
            self.isLoading = false
            print("Error fetching patients: \(error.localizedDescription)")
        }
    }
}
