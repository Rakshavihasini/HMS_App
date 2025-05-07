import SwiftUI
import PDFKit
import UIKit
import FirebaseFirestore


struct ReadOnlyConsultationNotesView: View {
    // Add appointment ID parameter
    var appointmentId: String
    
    @Environment(\.colorScheme) var colorScheme
    @State private var doctorNotes: String = ""
    @State private var prescriptions: String = ""
    @State private var tests: String = ""
    @State private var patientName: String = ""
    @State private var patientId: String = ""
    @State private var doctorName: String = ""
    @State private var doctorId: String = "" 
    @State private var consultationDate = Date()
    @State private var showingPDFPreview = false
    @State private var pdfURL: URL? = nil
    @State private var showShareSheet = false
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    private var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    // Initialize with appointment data
    init(appointmentId: String) {
        self.appointmentId = appointmentId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading consultation data...")
                } else if let error = errorMessage {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                        Button("Try Again") {
                            fetchConsultationData()
                        }
                        .padding()
                        .background(currentTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Patient Information Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Patient Information")
                                    .font(.headline)
                                    .foregroundColor(currentTheme.primary)
                                
                                HStack(spacing: 15) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Patient Name")
                                            .font(.subheadline)
                                            .foregroundColor(currentTheme.text.opacity(0.7))
                                        
                                        TextField("Enter patient name", text: $patientName)
                                            .padding(10)
                                            .background(currentTheme.card)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(currentTheme.border, lineWidth: 1)
                                            )
                                            .disabled(true) // Make read-only
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Patient ID")
                                            .font(.subheadline)
                                            .foregroundColor(currentTheme.text.opacity(0.7))
                                        
                                        TextField("Enter patient ID", text: $patientId)
                                            .padding(10)
                                            .background(currentTheme.card)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(currentTheme.border, lineWidth: 1)
                                            )
                                            .disabled(true) // Make read-only
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Doctor Name")
                                        .font(.subheadline)
                                        .foregroundColor(currentTheme.text.opacity(0.7))
                                    
                                    TextField("Enter doctor name", text: $doctorName)
                                        .padding(10)
                                        .background(currentTheme.card)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(currentTheme.border, lineWidth: 1)
                                        )
                                        .disabled(true) // Make read-only
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Consultation Date")
                                        .font(.subheadline)
                                        .foregroundColor(currentTheme.text.opacity(0.7))
                                    
                                    DatePicker("", selection: $consultationDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .padding(10)
                                        .background(currentTheme.card)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(currentTheme.border, lineWidth: 1)
                                        )
                                        .disabled(true) // Make read-only
                                }
                            }
                            .padding()
                            .background(currentTheme.background.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Doctor Notes Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Doctor Notes")
                                    .font(.headline)
                                    .foregroundColor(currentTheme.primary)
                                
                                TextEditor(text: $doctorNotes)
                                    .frame(minHeight: 150)
                                    .padding(10)
                                    .background(currentTheme.card)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(currentTheme.border, lineWidth: 1)
                                    )
                                    .disabled(true) // Make read-only
                            }
                            .padding()
                            .background(currentTheme.background.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Prescriptions Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Prescriptions")
                                    .font(.headline)
                                    .foregroundColor(currentTheme.primary)
                                
                                TextEditor(text: $prescriptions)
                                    .frame(minHeight: 120)
                                    .padding(10)
                                    .background(currentTheme.card)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(currentTheme.border, lineWidth: 1)
                                    )
                                    .disabled(true) // Make read-only
                                
                                Text("Format: Medication name, dosage, frequency, duration")
                                    .font(.caption)
                                    .foregroundColor(currentTheme.text.opacity(0.6))
                            }
                            .padding()
                            .background(currentTheme.background.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Tests Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recommended Tests")
                                    .font(.headline)
                                    .foregroundColor(currentTheme.primary)
                                
                                TextEditor(text: $tests)
                                    .frame(minHeight: 120)
                                    .padding(10)
                                    .background(currentTheme.card)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(currentTheme.border, lineWidth: 1)
                                    )
                                    .disabled(true) // Make read-only
                            }
                            .padding()
                            .background(currentTheme.background.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Share PDF Button (only if PDF exists)
                            if let _ = pdfURL {
                                Button(action: {
                                    showShareSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share PDF")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(currentTheme.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(color: currentTheme.shadow, radius: 3)
                                }
                                .padding(.top, 10)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(currentTheme.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("Consultation Notes")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPDFPreview) {
                if let url = pdfURL {
                    PDFPreviewView(url: url)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
            .onAppear {
                fetchConsultationData()
            }
        }
    }
    
    // Function to fetch consultation data
    private func fetchConsultationData() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        // First check if there's existing consultation data
        db.collection("consult").document(appointmentId).getDocument { (consultDoc, consultError) in
            if let consultError = consultError {
                self.errorMessage = "Failed to fetch consultation: \(consultError.localizedDescription)"
                self.isLoading = false
                return
            }
            
            if let consultDoc = consultDoc, consultDoc.exists, let consultData = consultDoc.data() {
                // Populate fields with existing consultation data
                if let doctorNotes = consultData["doctorNotes"] as? String {
                    self.doctorNotes = doctorNotes
                }
                
                if let prescriptions = consultData["prescriptions"] as? String {
                    self.prescriptions = prescriptions
                }
                
                if let tests = consultData["recommendedTests"] as? String {
                    self.tests = tests
                }
                
                if let patientName = consultData["patientName"] as? String {
                    self.patientName = patientName
                }
                
                if let patientId = consultData["patientId"] as? String {
                    self.patientId = patientId
                }
                
                if let doctorName = consultData["doctorName"] as? String {
                    self.doctorName = doctorName
                }
                
                if let doctorId = consultData["doctorId"] as? String {
                    self.doctorId = doctorId
                }
                
                if let timestamp = consultData["consultationDate"] as? Timestamp {
                    self.consultationDate = timestamp.dateValue()
                }
                
                // Check if there's a PDF file name
                if let pdfFileName = consultData["pdfFileName"] as? String {
                    // Create a URL to the PDF in the temporary directory
                    let tempDir = FileManager.default.temporaryDirectory
                    self.pdfURL = tempDir.appendingPathComponent(pdfFileName)
                }
                
                self.isLoading = false
            } else {
                // If no consultation data exists, fetch appointment data
                self.fetchAppointmentData(db: db)
            }
        }
    }
    
    // Helper method to fetch appointment data if no consultation exists
    private func fetchAppointmentData(db: Firestore) {
        db.collection("hms4_appointments").document(appointmentId).getDocument { (document, error) in
            if let error = error {
                self.errorMessage = "Failed to fetch appointment: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            guard let document = document, document.exists else {
                self.errorMessage = "Appointment not found"
                self.isLoading = false
                return
            }
            
            if let data = document.data() {
                // Parse appointment data
                self.patientId = data["patId"] as? String ?? ""
                self.doctorId = data["docId"] as? String ?? ""
                self.doctorName = data["docName"] as? String ?? ""                
                
                // Parse date
                if let dateString = data["date"] as? String {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    if let date = dateFormatter.date(from: dateString) {
                        self.consultationDate = date
                    }
                } else if let timestamp = data["consultationDate"] as? Timestamp {
                    self.consultationDate = timestamp.dateValue()
                }
                
                // Pre-populate reason as initial doctor notes if available
                if let reason = data["reason"] as? String, !reason.isEmpty {
                    self.doctorNotes = "Initial complaint: \(reason)\n\nNo consultation notes available yet."
                } else {
                    self.doctorNotes = "No consultation notes available yet."
                }
                
                // Set placeholder messages
                self.prescriptions = "No prescriptions available yet."
                self.tests = "No recommended tests available yet."
                
                // Continue with fetching patient data
                self.fetchPatientData(db: db)
            } else {
                self.errorMessage = "No appointment data found"
                self.isLoading = false
            }
        }
    }
    
    // Helper method to fetch patient data
    private func fetchPatientData(db: Firestore) {
        if !self.patientId.isEmpty {
            db.collection("hms4_patients").document(self.patientId).getDocument { (patientDoc, patientError) in
                if let patientError = patientError {
                    print("Error fetching patient data: \(patientError.localizedDescription)")
                    self.errorMessage = "Could not fetch patient information"
                    self.isLoading = false
                    return
                }
                
                if let patientDoc = patientDoc, patientDoc.exists, let patientData = patientDoc.data() {
                    // Get patient name from patient document
                    if let name = patientData["name"] as? String {
                        self.patientName = name
                    } else {
                        // If no name found, use a placeholder
                        self.patientName = "Unknown Patient"
                    }
                } else {
                    // If patient document not found
                    self.patientName = "Patient ID: \(self.patientId)"
                }
                
                self.isLoading = false
            }
        } else {
            // If no patientId
            self.patientName = "No Patient ID"
            self.isLoading = false
        }
    }
}




