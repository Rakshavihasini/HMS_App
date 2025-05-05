import SwiftUI
import FirebaseStorage
import UniformTypeIdentifiers


struct PatientDocumentsView: View {
    // MARK: - Properties
    
    /// The patient ID to fetch documents for
    let patientId: String
    
    /// Optional title override
    var title: String?
    
    @State private var documents: [PatientDocument] = []
    @State private var isLoading: Bool = false
    @State private var isUploading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingError: Bool = false
    @State private var selectedDocument: PatientDocument? = nil
    @State private var showingDocumentViewer: Bool = false
    @State private var showingDocumentPicker: Bool = false
    @State private var uploadProgress: Double = 0.0
    @State private var showingUploadProgress: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var documentToDelete: PatientDocument? = nil
    @State private var showingMedicalRecordsChat: Bool = false
    @State private var selectedDocumentURL: URL? = nil
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content
            if isLoading {
                loadingView()
            } else if documents.isEmpty {
                emptyStateView()
            } else {
                documentListView()
            }
            
            // Upload progress overlay
            if showingUploadProgress {
                uploadProgressView()
                    .transition(.opacity)
            }
            
            // Only keep the upload FAB, remove chat button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // Upload button
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 3)
                    }
                    .padding()
                    .disabled(isUploading)
                }
            }
        }
        .navigationTitle(title ?? "Patient Documents")
        .onAppear {
            fetchDocuments()
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingDocumentViewer) {
            if let document = selectedDocument {
                NavigationView {
                    DocumentViewerView(
                        documentPath: document.path,
                        title: document.name
                    )
                    .navigationBarItems(trailing: Button("Done") {
                        showingDocumentViewer = false
                    })
                }
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { urls in
                if !urls.isEmpty {
                    uploadDocuments(urls: urls)
                }
            }
        }
        // Update the sheet presentation for MedicalRecordsChat
        .sheet(isPresented: $showingMedicalRecordsChat) {
            MedicalRecordsChatView(documentURL: selectedDocumentURL)
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Document"),
                message: Text("Are you sure you want to delete \(documentToDelete?.name ?? "this document")?\nThis action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let document = documentToDelete {
                        deleteDocument(document: document)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - View Components
    
    /// Loading view with activity indicator
    private func loadingView() -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading documents...")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    /// Empty state view when no documents are found
    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No documents found")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button("Refresh") {
                    fetchDocuments()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Upload Document") {
                    showingDocumentPicker = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Document list view with chat cue
    private func documentListView() -> some View {
        VStack {
            // Add a subtle chat cue at the top
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Tip: Long-press on a document to chat about its contents")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.yellow.opacity(0.1))
            
            List {
                ForEach(documents) { document in
                    Button(action: {
                        selectedDocument = document
                        showingDocumentViewer = true
                        
                        // Get the URL for the document to potentially use with chat
                        getDocumentURL(for: document)
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
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            documentToDelete = document
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        // Add a swipe action for chat as well
                        Button {
                            selectedDocument = document
                            getDocumentURL(for: document) { url in
                                if let url = url {
                                    print("Document URL obtained: \(url)") // Add debug print
                                    self.selectedDocumentURL = url
                                    self.showingMedicalRecordsChat = true
                                } else {
                                    errorMessage = "Could not load document for chat"
                                    showingError = true
                                }
                            }
                        } label: {
                            Label("Chat", systemImage: "message.fill")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button(action: {
                            selectedDocument = document
                            getDocumentURL(for: document) { url in
                                if let url = url {
                                    print("Document URL obtained: \(url)") // Add debug print
                                    self.selectedDocumentURL = url
                                    self.showingMedicalRecordsChat = true
                                } else {
                                    errorMessage = "Could not load document for chat"
                                    showingError = true
                                }
                            }
                        }) {
                            Label("Chat about this document", systemImage: "message.fill")
                        }
                    }
                }
            }
            .refreshable {
                await refreshDocuments()
            }
        }
    }
    
    /// Upload progress view
    private func uploadProgressView() -> some View {
        VStack(spacing: 16) {
            ProgressView(value: uploadProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 200)
            
            Text("Uploading document...")
                .font(.headline)
            
            Text("\(Int(uploadProgress * 100))%")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(Color(UIColor.systemBackground))
            .shadow(radius: 5))
    }
    
    // MARK: - Helper Methods
    
    private func documentTypeIcon(for type: String) -> String {
        switch type {
        case "PDF": return "doc.text"
        case "Image": return "photo"
        default: return "doc"
        }
    }
    
    // Get the URL for a document
    private func getDocumentURL(for document: PatientDocument, completion: ((URL?) -> Void)? = nil) {
        let storage = Storage.storage()
        let documentRef = storage.reference(withPath: document.path)
        
        documentRef.downloadURL { url, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error getting document URL: \(error.localizedDescription)")
                    completion?(nil)
                    return
                }
                
                if let url = url {
                    self.selectedDocumentURL = url
                    completion?(url)
                } else {
                    completion?(nil)
                }
            }
        }
    }
    
    // MARK: - Data Methods
    
    /// Fetch documents (async version for pull-to-refresh)
    private func refreshDocuments() async {
        // Wrap the existing fetch method in an async Task
        return await withCheckedContinuation { continuation in
            fetchDocuments {
                continuation.resume()
            }
        }
    }
    
    /// Fetch documents with optional completion handler
    private func fetchDocuments(completion: (() -> Void)? = nil) {
        guard !patientId.isEmpty else { 
            completion?()
            return 
        }
        
        isLoading = true
        documents = []
        
        let storage = Storage.storage()
        let patientFolderPath = "hms4/patients/\(patientId)"
        let storageRef = storage.reference().child(patientFolderPath)
        
        // List all items in the patient's folder
        storageRef.listAll { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Error fetching documents: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                    completion?()
                    return
                }
                
                // Process items and prefixes (subfolders)
                var patientDocuments: [PatientDocument] = []
                
                // Add direct files
                for item in result?.items ?? [] {
                    patientDocuments.append(PatientDocument(
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
                                documents = patientDocuments + subDocuments
                                isLoading = false
                                completion?()
                            }
                        } else {
                            DispatchQueue.main.async {
                                documents = patientDocuments
                                isLoading = false
                                completion?()
                            }
                        }
                    }
                } else {
                    documents = patientDocuments
                    isLoading = false
                    completion?()
                }
            }
        }
    }
    
    /// Upload documents to Firebase Storage
    private func uploadDocuments(urls: [URL]) {
        guard !patientId.isEmpty else {
            errorMessage = "Patient ID is required"
            showingError = true
            return
        }
        
        isUploading = true
        showingUploadProgress = true
        uploadProgress = 0.0
        
        let storage = Storage.storage()
        let patientFolderPath = "hms4/patients/\(patientId)/medical_records"
        
        // Process each document sequentially
        uploadNextDocument(urls: urls, index: 0, folderPath: patientFolderPath, storage: storage) { success in
            DispatchQueue.main.async {
                isUploading = false
                showingUploadProgress = false
                
                if success {
                    // Refresh the document list
                    fetchDocuments()
                } else {
                    errorMessage = "Failed to upload one or more documents"
                    showingError = true
                }
            }
        }
    }
    
    /// Helper method to upload documents sequentially
    private func uploadNextDocument(urls: [URL], index: Int, folderPath: String, storage: Storage, completion: @escaping (Bool) -> Void) {
        // Check if we've processed all documents
        if index >= urls.count {
            completion(true)
            return
        }
        
        let url = urls[index]
        let filename = url.lastPathComponent
        let storageRef = storage.reference().child("\(folderPath)/\(filename)")
        
        // Create a file metadata object
        let metadata = StorageMetadata()
        
        // Set content type based on file extension
        let fileExtension = url.pathExtension.lowercased()
        if fileExtension == "pdf" {
            metadata.contentType = "application/pdf"
        } else if ["jpg", "jpeg"].contains(fileExtension) {
            metadata.contentType = "image/jpeg"
        } else if fileExtension == "png" {
            metadata.contentType = "image/png"
        } else if fileExtension == "gif" {
            metadata.contentType = "image/gif"
        }
        
        // Upload the file - fix the ambiguous method call
        let uploadTask: StorageUploadTask = storageRef.putFile(from: url, metadata: metadata)
        
        // Monitor upload progress
        uploadTask.observe(StorageTaskStatus.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let individualProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            
            // Calculate overall progress (current file progress + completed files)
            let overallProgress = (Double(index) + individualProgress) / Double(urls.count)
            
            DispatchQueue.main.async {
                uploadProgress = overallProgress
            }
        }
        
        // Handle upload completion
        uploadTask.observe(StorageTaskStatus.success) { _ in
            // Move to the next document
            uploadNextDocument(urls: urls, index: index + 1, folderPath: folderPath, storage: storage, completion: completion)
        }
        
        uploadTask.observe(StorageTaskStatus.failure) { snapshot in
            if let error = snapshot.error {
                print("Error uploading document: \(error.localizedDescription)")
            }
            // Continue with next document even if this one failed
            uploadNextDocument(urls: urls, index: index + 1, folderPath: folderPath, storage: storage, completion: completion)
        }
    }
    
    /// Delete a document from Firebase Storage
    private func deleteDocument(document: PatientDocument) {
        let storage = Storage.storage()
        let documentRef = storage.reference(withPath: document.path)
        
        documentRef.delete { error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Error deleting document: \(error.localizedDescription)"
                    showingError = true
                } else {
                    // Remove the document from the local array
                    if let index = documents.firstIndex(where: { $0.id == document.id }) {
                        documents.remove(at: index)
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider

struct PatientDocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PatientDocumentsView(patientId: "sample_patient_id")
        }
    }
}
