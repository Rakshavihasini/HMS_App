import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct PatientDocument: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    var documentType: String {
        let ext = name.components(separatedBy: ".").last?.lowercased() ?? ""
        switch ext {
        case "pdf": return "PDF"
        case "jpg", "jpeg", "png", "gif": return "Image"
        default: return "Document"
        }
    }
}

struct DocumentViewerTestView: View {
    // For manual URL entry
    @State private var documentURL = ""
    @State private var showingDocumentViewer = false
    @State private var errorMessage: String? = nil
    @State private var showingError = false
    
    // For patient documents
    @State private var patientId = ""
    @State private var patientDocuments: [PatientDocument] = []
    @State private var isLoadingDocuments = false
    @State private var selectedDocument: PatientDocument? = nil
    @State private var showingPatientDocumentViewer = false
    @State private var showPatientDocumentsList = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Document Viewer Test")
                    .font(.largeTitle)
                    .padding(.top, 30)
                
                // Patient Documents Section
                VStack(spacing: 15) {
                    Text("View Patient Documents")
                        .font(.headline)
                    
                    HStack {
                        TextField("Enter Patient ID", text: $patientId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button("Fetch") {
                            fetchPatientDocuments(patientId: patientId)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(patientId.isEmpty || isLoadingDocuments)
                    }
                    .padding(.horizontal)
                    
                    if isLoadingDocuments {
                        ProgressView("Loading documents...")
                    } else if !patientDocuments.isEmpty {
                        Button("View \(patientDocuments.count) Documents") {
                            showPatientDocumentsList = true
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical)
                
                // Manual URL Entry Section
                Text("Or Enter Document URL Directly")
                    .font(.headline)
                
                TextField("Firebase URL or path", text: $documentURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button("View Document") {
                    if documentURL.isEmpty {
                        errorMessage = "Please enter a URL or path"
                        showingError = true
                        return
                    }
                    showingDocumentViewer = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Examples:")
                        .font(.headline)
                    
                    Text("• Firebase path: hms4/patients/user123/medical_records/document.pdf")
                        .font(.caption)
                    
                    Text("• HTTP URL: https://firebasestorage.googleapis.com/...")
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding()
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingDocumentViewer) {
                NavigationView {
                    DocumentViewerView(
                        documentPath: documentURL,
                        title: getDocumentTitle(from: documentURL)
                    )
                    .navigationBarItems(trailing: Button("Done") {
                        showingDocumentViewer = false
                    })
                }
            }
            .sheet(isPresented: $showingPatientDocumentViewer) {
                if let document = selectedDocument {
                    NavigationView {
                        DocumentViewerView(
                            documentPath: document.path,
                            title: document.name
                        )
                        .navigationBarItems(trailing: Button("Done") {
                            showingPatientDocumentViewer = false
                        })
                    }
                }
            }
            .sheet(isPresented: $showPatientDocumentsList) {
                NavigationView {
                    List {
                        ForEach(patientDocuments) { document in
                            Button(action: {
                                selectedDocument = document
                                showPatientDocumentsList = false
                                showingPatientDocumentViewer = true
                            }) {
                                HStack {
                                    Image(systemName: documentTypeIcon(for: document.documentType))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading) {
                                        Text(document.name)
                                            .fontWeight(.medium)
                                        Text(document.documentType)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .navigationTitle("Patient Documents")
                    .navigationBarItems(trailing: Button("Done") {
                        showPatientDocumentsList = false
                    })
                }
            }
        }
    }
    
    private func documentTypeIcon(for type: String) -> String {
        switch type {
        case "PDF": return "doc.text"
        case "Image": return "photo"
        default: return "doc"
        }
    }
    
    private func getDocumentTitle(from path: String) -> String {
        if path.hasPrefix("http"), let url = URL(string: path) {
            return url.lastPathComponent
        } else {
            let components = path.components(separatedBy: "/")
            return components.last ?? "Document"
        }
    }
    
    private func fetchPatientDocuments(patientId: String) {
        guard !patientId.isEmpty else { return }
        
        isLoadingDocuments = true
        patientDocuments = []
        
        let storage = Storage.storage()
        let patientFolderPath = "hms4/patients/\(patientId)"
        let storageRef = storage.reference().child(patientFolderPath)
        
        // List all items in the patient's folder
        storageRef.listAll { result, error in
            DispatchQueue.main.async {
                isLoadingDocuments = false
                
                if let error = error {
                    errorMessage = "Error fetching documents: \(error.localizedDescription)"
                    showingError = true
                    return
                }
                
                // Process items and prefixes (subfolders)
                var documents: [PatientDocument] = []
                
                // Add direct files
                for item in result?.items ?? [] {
                    documents.append(PatientDocument(
                        name: item.name,
                        path: "\(patientFolderPath)/\(item.name)"
                    ))
                }
                
                // Check for medical_records subfolder
                let medicalRecordsPrefix = result?.prefixes.first(where: { $0.name == "medical_records" })
                
                if let medicalRecordsRef = medicalRecordsPrefix {
                    // List files in medical_records subfolder
                    medicalRecordsRef.listAll { subResult, subError in
                        if let subItems = subResult?.items, !subItems.isEmpty {
                            let subDocuments = subItems.map { item in
                                PatientDocument(
                                    name: item.name,
                                    path: "\(patientFolderPath)/medical_records/\(item.name)"
                                )
                            }
                            
                            DispatchQueue.main.async {
                                patientDocuments = documents + subDocuments
                            }
                        } else {
                            DispatchQueue.main.async {
                                patientDocuments = documents
                            }
                        }
                    }
                } else {
                    patientDocuments = documents
                }
            }
        }
    }
}

struct DocumentViewerTestView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentViewerTestView()
    }
}