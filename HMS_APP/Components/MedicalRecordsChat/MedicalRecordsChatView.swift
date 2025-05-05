import SwiftUI
import PDFKit
import FirebaseCore
import FirebaseVertexAI
import MarkdownUI

struct MedicalRecordsChatView: View {
    // MARK: - Properties
    @State private var selectedDocument: URL?
    @State private var documentContent: String = ""
    @State private var isProcessingDocument: Bool = false
    @State private var chatMessages: [ChatMessage] = []
    @State private var currentMessage: String = ""
    @State private var isLoadingResponse: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var documentTitle: String = ""
    @State private var errorMessage: String? = nil
    
    // Service for handling medical info queries
    private let medicalInfoService = MedicalInfoService()
    
    // Initialize with optional document URL
    init(documentURL: URL? = nil) {
        print("MedicalRecordsChatView initialized with URL: \(String(describing: documentURL))") // Add debug print
        _selectedDocument = State(initialValue: documentURL)
        
        // If document is provided, set the title and processing state
        if let url = documentURL {
            _documentTitle = State(initialValue: url.lastPathComponent)
            _isProcessingDocument = State(initialValue: true)
        } else {
            _documentTitle = State(initialValue: "Medical Records Chat")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Always show chat view
            chatView
        }
        .sheet(isPresented: $showDocumentPicker) {
            PatientDocumentPicker { url in
                handleSelectedDocument(url: url)
            }
        }
        .alert(isPresented: Binding<Bool>(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            // Process the document if one was provided in init
            if let url = selectedDocument {
                handleSelectedDocument(url: url)
            } else {
                // Add a welcome message when no document is selected
                chatMessages.append(ChatMessage(
                    id: UUID(),
                    content: "Welcome to Medical Records Chat! Upload a document using the button below or ask a general health question.",
                    isUser: false,
                    suggestedQuestions: ["What are common health screenings I should get?", "How can I maintain a healthy lifestyle?", "What information should I keep in my medical records?"]
                ))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showDocumentPicker = true
                }) {
                    Image(systemName: "doc.badge.plus")
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerView: some View {
        HStack {
            if selectedDocument != nil {
                Button(action: {
                    // Reset chat
                    selectedDocument = nil
                    documentContent = ""
                    chatMessages = []
                    
                    // Add welcome message
                    chatMessages.append(ChatMessage(
                        id: UUID(),
                        content: "Welcome to Medical Records Chat! Upload a document using the button below or ask a general health question.",
                        isUser: false,
                        suggestedQuestions: ["What are common health screenings I should get?", "How can I maintain a healthy lifestyle?", "What information should I keep in my medical records?"]
                    ))
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                }
                
                Spacer()
                
                Text(documentTitle)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: {
                    // Show document preview
                }) {
                    Image(systemName: "doc.text.magnifyingglass")
                }
            } else {
                Text("Medical Records Chat")
                    .font(.headline)
                Spacer()
            }
        }
        .padding()
        .background(Color.medicareBlue.opacity(0.1))
    }
    
    // Remove emptyStateView and keep only chatView
    
    private var chatView: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isProcessingDocument {
                        processingView
                    }
                    
                    ForEach(chatMessages) { message in
                        chatBubble(message: message)
                    }
                    
                    if isLoadingResponse {
                        loadingBubble
                    }
                }
                .padding()
            }
            
            // Input field with upload button
            HStack {
                if selectedDocument == nil {
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 22))
                            .foregroundColor(.medicareBlue)
                    }
                    .padding(.trailing, 4)
                }
                
                TextField("Ask a question...", text: $currentMessage)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.medicareBlue)
                }
                .disabled(currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoadingResponse)
            }
            .padding()
        }
    }
    
    private var processingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.bottom, 4)
                Text("Processing your medical record...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            Spacer()
        }
    }
    
    private var loadingBubble: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(18)
        }
    }
    
    private func chatBubble(message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if message.isUser {
                    Spacer()
                    Text(message.content)
                        .padding(12)
                        .background(Color.medicareBlue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "stethoscope")
                                .foregroundColor(.medicareBlue)
                            Text("HealthBuddy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Use MarkdownUI to render markdown content
                        Markdown(message.content)
                            .markdownTheme(.basic)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(18)
                    }
                    Spacer()
                }
            }
            
            // Display suggested questions if available and not a user message
            if !message.isUser, let questions = message.suggestedQuestions, !questions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(questions, id: \.self) { question in
                        Button(action: {
                            // Set the question as the current message and send it
                            self.currentMessage = question
                            self.sendMessage()
                        }) {
                            Text(question)
                                .font(.subheadline)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.medicareBlue.opacity(0.1))
                                .foregroundColor(.medicareBlue)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.medicareBlue.opacity(0.3), lineWidth: 1)
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Methods
    
    private func handleSelectedDocument(url: URL) {
        selectedDocument = url
        documentTitle = url.lastPathComponent
        isProcessingDocument = true
        
        // Extract text from document
        extractTextFromDocument(url: url) { result in
            switch result {
            case .success(let text):
                self.documentContent = text
                self.processDocument(text: text)
            case .failure(let error):
                self.errorMessage = "Failed to process document: \(error.localizedDescription)"
                self.isProcessingDocument = false
            }
        }
    }
    
    private func extractTextFromDocument(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // Implement text extraction based on file type (PDF or image)
        if url.pathExtension.lowercased() == "pdf" {
            // Extract text from PDF
            if let pdf = PDFDocument(url: url) {
                var text = ""
                for i in 0..<pdf.pageCount {
                    if let page = pdf.page(at: i), let pageText = page.string {
                        text += pageText + "\n"
                    }
                }
                completion(.success(text))
            } else {
                completion(.failure(NSError(domain: "MedicalRecordsChat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load PDF"])))
            }
        } else {
            // For images, we would need OCR
            // This is a placeholder - in a real app, you'd use Vision framework or a cloud OCR service
            completion(.failure(NSError(domain: "MedicalRecordsChat", code: 2, userInfo: [NSLocalizedDescriptionKey: "OCR for images not implemented"])))
        }
    }
    
    private func processDocument(text: String) {
        Task {
            do {
                let (initialResponse, suggestedQuestions) = try await medicalInfoService.processUserQuery(
                    query: "Provide a concise summary of this medical record.",
                    documentContext: text
                )
                
                DispatchQueue.main.async {
                    self.isProcessingDocument = false
                    self.chatMessages.append(ChatMessage(
                        id: UUID(), 
                        content: initialResponse, 
                        isUser: false,
                        suggestedQuestions: suggestedQuestions
                    ))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessingDocument = false
                    self.errorMessage = "Failed to analyze document: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func sendMessage() {
        let messageText = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        let userMessage = ChatMessage(id: UUID(), content: messageText, isUser: true)
        chatMessages.append(userMessage)
        currentMessage = ""
        isLoadingResponse = true
        
        Task {
            do {
                let (response, suggestedQuestions) = try await medicalInfoService.processUserQuery(
                    query: messageText,
                    documentContext: documentContent
                )
                
                DispatchQueue.main.async {
                    self.isLoadingResponse = false
                    self.chatMessages.append(ChatMessage(
                        id: UUID(), 
                        content: response, 
                        isUser: false,
                        suggestedQuestions: suggestedQuestions
                    ))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingResponse = false
                    self.errorMessage = "Failed to get response: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    var suggestedQuestions: [String]? // Add this property to store suggested questions
}

struct SuggestedQuestion: Identifiable {
    let id = UUID()
    let text: String
}
