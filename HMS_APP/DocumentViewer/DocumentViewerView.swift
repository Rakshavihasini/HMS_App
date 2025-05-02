import SwiftUI
import PDFKit
import QuickLook
import FirebaseStorage
import FirebaseStorageCombineSwift
import Combine

/// A standalone view component for displaying PDF documents and images
/// Optimized for Firebase Storage with caching support
struct DocumentViewerView: View {
    // MARK: - Properties
    
    /// The document path or URL to display
    /// Can be:
    /// - A Firebase Storage path (e.g., "patient_records/patient123/record.pdf")
    /// - A complete URL (local or remote)
    let documentPath: String
    
    /// Optional title to display in the navigation bar
    var title: String?
    
    /// Optional callback when the view is dismissed
    var onDismiss: (() -> Void)?
    
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var localURL: URL? = nil
    @State private var previewItem: PreviewItem? = nil
    @State private var showPreview: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var documentType: DocumentType = .unknown
    
    // MARK: - Enums
    
    /// Document type enum to track the type of document
    private enum DocumentType {
        case pdf
        case image
        case unknown
    }
    
    // MARK: - Computed Properties
    
    /// Determines if the document is a PDF based on its file extension or URL path
    private var isPDF: Bool {
        // Check if the URL contains .pdf before any query parameters
        if documentPath.lowercased().contains(".pdf?") {
            return true
        }
        // Also keep the original check for simple paths
        return documentPath.lowercased().hasSuffix(".pdf")
    }
    
    /// Determines if the document is an image based on common image file extensions
    private var isImage: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "heif", "webp", "tiff", "bmp"]
        
        // Check for extensions before query parameters
        for ext in imageExtensions {
            if documentPath.lowercased().contains(".\(ext)?") {
                return true
            }
        }
        
        // Also keep the original check for simple paths
        return imageExtensions.contains { documentPath.lowercased().hasSuffix(".\($0)") }
    }
    
    /// Determines if the path is a Firebase Storage path or a complete URL
    private var isFirebasePath: Bool {
        return !(documentPath.hasPrefix("http://") || 
                documentPath.hasPrefix("https://") || 
                documentPath.hasPrefix("file://"))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content
            if let errorMessage = errorMessage{
                errorView(message: errorMessage)
            } else if isLoading {
                loadingView()
            } else if documentType == .pdf || isPDF, let url = localURL {
                pdfView(url: url)
            } else if documentType == .image || isImage, let url = localURL {
                imageView(url: url)
            } else if let url = localURL {
                // For other file types, use QuickLook
                Button("Open Document") {
                    previewItem = PreviewItem(url: url, title: title ?? "Document")
                    showPreview = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Text("Unable to load document")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle(title ?? "Document Viewer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let url = localURL {
                    Button(action: {
                        previewItem = PreviewItem(url: url, title: title ?? "Document")
                        showPreview = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .onAppear {
            loadDocument()
        }
        .sheet(isPresented: $showPreview) {
            if let previewItem = previewItem {
                QuickLookPreview(previewItem: previewItem)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads the document from the provided path or URL
    private func loadDocument() {
        isLoading = true
        errorMessage = nil
        
        // Check if we have a cached version first
        if let cachedURL = getCachedDocumentURL(for: documentPath) {
            self.localURL = cachedURL
            self.isLoading = false
            return
        }
        
        // Handle different document sources
        if isFirebasePath {
            // Firebase Storage path
            downloadFromFirebase(path: documentPath)
        } else if let url = URL(string: documentPath) {
            if url.scheme == "file" {
                // Local file
                if FileManager.default.fileExists(atPath: url.path) {
                    self.localURL = url
                    self.isLoading = false
                } else {
                    self.errorMessage = "Document not found at specified location"
                    self.isLoading = false
                }
            } else {
                // Remote URL (not Firebase)
                downloadFromURL(url: url)
            }
        } else {
            self.errorMessage = "Invalid document path"
            self.isLoading = false
        }
    }
    
    /// Downloads a document from Firebase Storage
    private func downloadFromFirebase(path: String) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child(path)
        
        // Generate a local filename based on the path
        let filename = path.replacingOccurrences(of: "/", with: "_")
        let localURL = getDocumentCacheDirectory().appendingPathComponent(filename)
        
        // Check if we already have this file cached
        if FileManager.default.fileExists(atPath: localURL.path) {
            self.localURL = localURL
            self.isLoading = false
            return
        }
        
        // Download the file
        storageRef.write(toFile: localURL)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to download: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            } receiveValue: { url in
                DispatchQueue.main.async {
                    self.localURL = url
                    
                    // Determine document type from metadata if possible
                    storageRef.getMetadata { metadata, error in
                        if let contentType = metadata?.contentType {
                            if contentType.contains("pdf") {
                                self.documentType = .pdf
                            } else if contentType.contains("image") {
                                self.documentType = .image
                            }
                        }
                        self.isLoading = false
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Downloads a document from a remote URL
    private func downloadFromURL(url: URL) {
        // Generate a cache filename based on the URL
        let filename = url.lastPathComponent
        let localURL = getDocumentCacheDirectory().appendingPathComponent(filename)
        
        // Check if we already have this file cached
        if FileManager.default.fileExists(atPath: localURL.path) {
            self.localURL = localURL
            self.isLoading = false
            return
        }
        
        // Download the file
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to download: \(error.localizedDescription)"
                } else if let data = data {
                    // Check content type from response
                    if let httpResponse = response as? HTTPURLResponse,
                       let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                        
                        if contentType.contains("pdf") {
                            self.documentType = .pdf
                        } else if contentType.contains("image") {
                            self.documentType = .image
                        }
                    }
                    
                    do {
                        try data.write(to: localURL)
                        self.localURL = localURL
                    } catch {
                        self.errorMessage = "Failed to save document: \(error.localizedDescription)"
                    }
                }
                self.isLoading = false
            }
        }.resume()
    }
    
    /// Gets the URL for a cached document if it exists
    private func getCachedDocumentURL(for path: String) -> URL? {
        let filename: String
        
        if isFirebasePath {
            filename = path.replacingOccurrences(of: "/", with: "_")
        } else if let url = URL(string: path) {
            filename = url.lastPathComponent
        } else {
            return nil
        }
        
        let localURL = getDocumentCacheDirectory().appendingPathComponent(filename)
        
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    /// Gets the directory for caching documents
    private func getDocumentCacheDirectory() -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let documentsCache = cacheDirectory.appendingPathComponent("DocumentCache")
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: documentsCache.path) {
            try? FileManager.default.createDirectory(at: documentsCache, withIntermediateDirectories: true)
        }
        
        return documentsCache
    }
    
    // MARK: - View Components
    
    /// Loading indicator view
    private func loadingView() -> some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading document...")
                .font(.headline)
                .padding(.top, 20)
        }
    }
    
    /// Error message view
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                loadDocument()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    /// PDF viewer using PDFKit
    private func pdfView(url: URL) -> some View {
        PDFKitView(url: url)
            .edgesIgnoringSafeArea(.bottom)
    }
    
    /// Image viewer
    private func imageView(url: URL) -> some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                            .clipped()
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Supporting Views

/// PDFKit wrapper for SwiftUI
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}

/// QuickLook preview wrapper for SwiftUI
struct QuickLookPreview: UIViewControllerRepresentable {
    let previewItem: PreviewItem
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        uiViewController.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookPreview
        
        init(parent: QuickLookPreview) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.previewItem
        }
    }
}

/// Preview item for QuickLook
class PreviewItem: NSObject, QLPreviewItem {
    let url: URL
    let title: String
    
    init(url: URL, title: String) {
        self.url = url
        self.title = title
        super.init()
    }
    
    var previewItemURL: URL? {
        return url
    }
    
    var previewItemTitle: String? {
        return title
    }
}

// MARK: - Preview Provider

struct DocumentViewerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DocumentViewerView(
                documentPath: "patient_records/sample.pdf",
                title: "Sample PDF"
            )
        }
    }
}
