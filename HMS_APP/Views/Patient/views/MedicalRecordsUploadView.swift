import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import PDFKit
import QuickLook

struct MedicalRecordsUploadView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var fileUploadService = FileUploadService()
    @State private var isShowingImagePicker = false
    @State private var isShowingDocumentPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var records: [MedicalRecord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var selectedRecord: MedicalRecord?
    @State private var isShowingPreview = false
    @State private var tempFileURL: URL?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else {
                uploadButtons
                
                if fileUploadService.isUploading {
                    uploadProgress
                }
                
                if records.isEmpty {
                    emptyStateView
                } else {
                    recordsList
                }
            }
        }
        .alert("Error", isPresented: $showingError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage ?? "An unknown error occurred")
        })
        .onAppear {
            loadRecords()
        }
        .navigationTitle("Medical Records")
        .sheet(isPresented: $isShowingDocumentPicker) {
            PatientDocumentPicker { url in
                handleSelectedFile(url: url)
            }
        }
        .sheet(isPresented: $isShowingPreview) {
            if let record = selectedRecord {
                RecordPreviewView(record: record)
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    uploadImage(uiImage)
                }
            }
        }
    }
    
    private var uploadButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                isShowingDocumentPicker = true
            }) {
                VStack {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                    Text("Upload PDF")
                        .font(.caption)
                }
                .frame(width: 120, height: 80)
                .background(Color.medicareBlue.opacity(0.1))
                .foregroundColor(.medicareBlue)
                .cornerRadius(10)
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 24))
                    Text("Upload Image")
                        .font(.caption)
                }
                .frame(width: 120, height: 80)
                .background(Color.medicareBlue.opacity(0.1))
                .foregroundColor(.medicareBlue)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var uploadProgress: some View {
        VStack {
            ProgressView(value: fileUploadService.progress)
                .progressViewStyle(LinearProgressViewStyle())
            Text("Uploading... \(Int(fileUploadService.progress * 100))%")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
                .padding()
            
            Text("No medical records uploaded yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Upload your medical documents or images to keep them organized")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
    
    private var recordsList: some View {
        List {
            ForEach(records) { record in
                Button(action: {
                    selectedRecord = record
                    isShowingPreview = true
                }) {
                    HStack {
                        Image(systemName: record.isPDF ? "doc.fill" : "photo")
                            .font(.title3)
                            .foregroundColor(record.isPDF ? .red : .blue)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading) {
                            Text(record.fileName)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Text(record.formattedDate)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func loadRecords() {
        print("Loading records for user: \(authManager.currentUserID)")
        isLoading = true
        
        if authManager.currentUserID.isEmpty {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "User not authenticated. Please log in again."
                self.showingError = true
                print("Error loading records: User not authenticated")
            }
            return
        }
        
        fileUploadService.getPatientRecords(patientId: authManager.currentUserID) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let fetchedRecords):
                    print("Successfully loaded \(fetchedRecords.count) records")
                    self.records = fetchedRecords
                case .failure(let error):
                    print("Failed to load records: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load records: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
    
    private func handleSelectedFile(url: URL) {
        print("Handling selected file: \(url.lastPathComponent)")
        
        // Create a temporary directory URL if needed
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFUploads", isDirectory: true)
        
        do {
            // Create the directory if it doesn't exist
            try FileManager.default.createDirectory(at: tempDir, 
                                                 withIntermediateDirectories: true)
            
            // Create a unique name for the temporary file
            let fileName = url.lastPathComponent
            let tempURL = tempDir.appendingPathComponent(fileName)
            
            print("Temporary file path: \(tempURL.path)")
            
            // Remove any existing temporary file
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
                print("Removed existing temporary file")
            }
            
            // Copy the file to our temporary location
            try FileManager.default.copyItem(at: url, to: tempURL)
            print("File copied to temporary location")
            
            // Store the temp URL for cleanup
            self.tempFileURL = tempURL
            
            // Read the data from our temporary file
            let data = try Data(contentsOf: tempURL)
            print("File data read successfully, size: \(data.count) bytes")
            
            // Detect file type properly based on extension
            let fileExtension = url.pathExtension.lowercased()
            let fileType: String
            
            if fileExtension == "pdf" {
                fileType = "application/pdf"
            } else if ["jpg", "jpeg"].contains(fileExtension) {
                fileType = "image/jpeg"
            } else if fileExtension == "png" {
                fileType = "image/png"
            } else if fileExtension == "heic" {
                fileType = "image/heic"
            } else {
                fileType = "application/octet-stream"
            }
            
            print("Detected file type: \(fileType) for extension: \(fileExtension)")
            
            uploadFile(data: data, fileName: fileName, fileType: fileType)
            
        } catch let error {
            print("Error handling file: \(error.localizedDescription)")
            errorMessage = "Error processing file: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func cleanup() {
        // Clean up temporary files
        if let tempURL = tempFileURL {
            try? FileManager.default.removeItem(at: tempURL)
            self.tempFileURL = nil
        }
    }
    
    private func uploadImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Couldn't process the selected image"
            showingError = true
            return
        }
        
        let fileName = "image_\(Date().timeIntervalSince1970).jpg"
        let fileType = "image/jpeg"
        
        uploadFile(data: data, fileName: fileName, fileType: fileType)
    }
    
    private func uploadFile(data: Data, fileName: String, fileType: String) {
        print("Starting upload for file: \(fileName)")
        print("Current user ID: \(authManager.currentUserID)")
        
        fileUploadService.uploadFile(data: data, fileName: fileName, patientId: authManager.currentUserID, fileType: fileType) { result in
            print("Upload completion handler called")
            switch result {
            case .success(let url):
                print("Upload successful, URL: \(url)")
                // Refresh the list after successful upload
                self.loadRecords()
            case .failure(let error):
                print("Upload failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}


struct RecordPreviewView: View {
    let record: MedicalRecord
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var loadedImage: UIImage?
    @State private var pdfDocument: PDFDocument?
    @State private var previewController: QLPreviewController?
    @State private var refreshToken = UUID()
    @State private var debugInfo: String = ""
    @State private var showDebug = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var fileUploadService = FileUploadService()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isLoading {
                    VStack {
                        ProgressView("Loading document...")
                            .padding()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color(.systemBackground))
                } else if let errorMessage = errorMessage {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Error: \(errorMessage)")
                                .foregroundColor(.red)
                                .padding()
                                .multilineTextAlignment(.center)
                            
                            Button("Try Again") {
                                refreshToken = UUID()
                                loadDocument()
                            }
                            .padding()
                            .foregroundColor(.blue)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            if showDebug {
                                Text(debugInfo)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color(.systemBackground))
                } else if record.isPDF, let pdf = pdfDocument {
                    PDFKitRepresentedView(document: pdf, id: refreshToken)
                        .id(refreshToken)
                } else if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Text("Unsupported file format")
                        .foregroundColor(.gray)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background(Color(.systemBackground))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .navigationTitle(record.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Refresh") {
                    refreshToken = UUID()
                    loadDocument()
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(showDebug ? "Hide Debug" : "Debug") {
                    showDebug.toggle()
                }
            }
        }
        .onAppear {
            loadDocument()
        }
    }
    
    private func loadDocument() {
        isLoading = true
        errorMessage = nil
        loadedImage = nil
        pdfDocument = nil
        debugInfo = "File: \(record.fileName)\nType: \(record.fileType)\nURL: \(record.downloadURL)\n"
        
        print("Starting to load document: \(record.fileName)")
        
        // First, check if we need to refresh the Firebase URL
        if record.downloadURL.contains("firebase") {
            debugInfo += "Firebase URL detected, attempting refresh\n"
            refreshFirebaseURL()
        } else {
            debugInfo += "Using direct URL\n"
            loadFromURL(record.downloadURL)
        }
    }
    
    private func refreshFirebaseURL() {
        fileUploadService.getRefreshedURL(for: record.downloadURL) { result in
            switch result {
            case .success(let freshURL):
                debugInfo += "URL refresh result: \(freshURL)\n"
                DispatchQueue.main.async {
                    loadFromURL(freshURL)
                }
            case .failure(let error):
                debugInfo += "URL refresh failed: \(error.localizedDescription)\n"
                DispatchQueue.main.async {
                    // Fall back to original URL if refresh fails
                    loadFromURL(record.downloadURL)
                }
            }
        }
    }
    
    private func loadFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "Invalid URL format"
            debugInfo += "Error: Invalid URL format\n"
            return
        }
        
        debugInfo += "Loading from URL: \(url.absoluteString)\n"
        print("Loading from URL: \(url.absoluteString)")
        
        // Create a proper URLRequest
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let response = response as? HTTPURLResponse {
                    debugInfo += "Response status: \(response.statusCode)\n"
                    print("Response status code: \(response.statusCode)")
                    
                    if response.statusCode == 403 {
                        self.isLoading = false
                        self.errorMessage = "Access denied. Try refreshing."
                        debugInfo += "403 Access Denied Error\n"
                        return
                    } else if response.statusCode != 200 {
                        self.isLoading = false
                        self.errorMessage = "Server error: \(response.statusCode)"
                        debugInfo += "HTTP Error: \(response.statusCode)\n"
                        return
                    }
                } else {
                    debugInfo += "No HTTP response received\n"
                }
                
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    debugInfo += "Network error: \(error)\n"
                    return
                }
                
                guard let data = data, !data.isEmpty else {
                    self.isLoading = false
                    self.errorMessage = "No data received"
                    debugInfo += "Error: No data received\n"
                    return
                }
                
                debugInfo += "Data received: \(data.count) bytes\n"
                print("Successfully received \(data.count) bytes")
                
                // Process based on file type
                if self.record.isPDF {
                    debugInfo += "Processing as PDF\n"
                    if let pdfDoc = PDFDocument(data: data) {
                        debugInfo += "PDF loaded: \(pdfDoc.pageCount) pages\n"
                        print("PDF loaded successfully with \(pdfDoc.pageCount) pages")
                        self.pdfDocument = pdfDoc
                        self.isLoading = false
                    } else {
                        debugInfo += "Failed to create PDF document\n"
                        print("Failed to create PDF document from data")
                        self.errorMessage = "Invalid PDF format"
                        self.isLoading = false
                    }
                } else if self.record.isImage {
                    debugInfo += "Processing as image\n"
                    if let image = UIImage(data: data) {
                        debugInfo += "Image loaded: \(image.size.width) x \(image.size.height)\n"
                        print("Image loaded successfully: \(image.size.width) x \(image.size.height)")
                        self.loadedImage = image
                        self.isLoading = false
                    } else {
                        debugInfo += "Failed to create image\n"
                        print("Failed to create image from data")
                        self.errorMessage = "Invalid image format"
                        self.isLoading = false
                    }
                } else {
                    debugInfo += "Unsupported file type\n"
                    print("Unsupported file type")
                    self.errorMessage = "Unsupported file type"
                    self.isLoading = false
                }
            }
        }
        
        task.resume()
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument
    let id: UUID // To force refresh
    
    func makeUIView(context: Context) -> PDFView {
        print("Creating new PDFView with document containing \(document.pageCount) pages")
        let pdfView = PDFView()
        
        // Configure the display settings
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)
        pdfView.backgroundColor = .white
        
        // Set the document after configuring display settings
        pdfView.document = document
        
        // Make sure we're showing the first page
        if let firstPage = document.page(at: 0) {
            pdfView.go(to: firstPage)
        }
        
        // Setup zooming
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 4.0
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit * 1.1
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        print("Updating PDFView with document")
        pdfView.document = document
        
        // Always go to the first page when updating to ensure content is visible
        if let firstPage = document.page(at: 0) {
            pdfView.go(to: firstPage)
        }
    }
} 
