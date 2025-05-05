import SwiftUI
import PDFKit
import UIKit
import FirebaseFirestore


struct ConsultationNotesView: View {
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
    @State private var isGeneratingPDF = false
    @State private var showShareSheet = false
    @State private var isSavingToFirebase = false
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
                    ProgressView("Loading appointment data...")
                } else if let error = errorMessage {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                        Button("Try Again") {
                            fetchAppointmentData()
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
                                            // .disabled(true) // Make read-only since it's from appointment
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
                                            .disabled(true) // Make read-only since it's from appointment
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
                                        .disabled(true) // Make read-only since it's from appointment
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
                                        .disabled(true) // Make read-only since it's from appointment
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
                            }
                            .padding()
                            .background(currentTheme.background.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Generate PDF Button
                            Button(action: {
                                isGeneratingPDF = true
                                isSavingToFirebase = true
                                generatePDF { url in
                                    self.pdfURL = url
                                    self.isGeneratingPDF = false
                                    
                                    // Save to Firebase
                                    self.saveConsultationToFirebase(pdfURL: url) { success in
                                        self.isSavingToFirebase = false
                                        self.showingPDFPreview = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text")
                                    Text(isGeneratingPDF ? "Processing..." : "Generate PDF")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(currentTheme.primary)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: currentTheme.shadow, radius: 3)
                            }
                            .disabled(isGeneratingPDF || isSavingToFirebase || patientName.isEmpty || doctorName.isEmpty)
                            .padding(.top, 10)
                        }
                        .padding()
                    }
                }
            }
            .background(currentTheme.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("Consultation Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let _ = pdfURL {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
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
                fetchAppointmentData()
            }
        }
    }
    
    // New function to fetch appointment data
    private func fetchAppointmentData() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
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
                    self.doctorNotes = "Initial complaint: \(reason)\n\n"
                }
                
                // Fetch patient name from hms4_patients collection
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
            } else {
                self.isLoading = false
            }
        }
    }
    
    private func saveConsultationToFirebase(pdfURL: URL, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // Use appointment ID as the consult ID
        let consultId = appointmentId
        
        // Create the consultation data
        let consultationData: [String: Any] = [
            "id": consultId,
            "patientId": patientId,
            "patientName": patientName,
            "doctorId": doctorId,
            "doctorName": doctorName,
            "consultationDate": Timestamp(date: consultationDate),
            "doctorNotes": doctorNotes,
            "prescriptions": prescriptions,
            "recommendedTests": tests,
            "createdAt": Timestamp(date: Date()),
            "pdfFileName": pdfURL.lastPathComponent,
            "appointmentId": appointmentId
        ]
        
        // Save to Firestore
        db.collection("consult").document(consultId).setData(consultationData) { error in
            if let error = error {
                print("Error saving consultation to Firestore: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Consultation saved successfully with ID: \(consultId)")
                
                // Update the appointment status to "Completed"
                db.collection("hms4_appointments").document(appointmentId).updateData([
                    "status": "Completed",
                    "consultationCompleted": true
                ]) { error in
                    if let error = error {
                        print("Error updating appointment status: \(error.localizedDescription)")
                    }
                }
                
                completion(true)
            }
        }
    }
    
    private func generatePDF(completion: @escaping (URL) -> Void) {
        // Create a temporary URL to store the PDF
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Consultation_\(patientName.replacingOccurrences(of: " ", with: "_"))_\(formattedDate).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Create PDF context
        let pageWidth: CGFloat = 8.5 * 72.0
        let pageHeight: CGFloat = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // PDF metadata
        let pdfMetaData = [
            kCGPDFContextCreator: "HMS App",
            kCGPDFContextAuthor: doctorName,
            kCGPDFContextTitle: "Medical Consultation"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        // Generate PDF document
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try renderer.writePDF(to: fileURL) { context in
                    // First page
                    context.beginPage()
                    
                    // Draw content on the PDF page
                    let titleFont = UIFont.boldSystemFont(ofSize: 24)
                    let headerFont = UIFont.boldSystemFont(ofSize: 16)
                    let regularFont = UIFont.systemFont(ofSize: 12)
                    let smallFont = UIFont.systemFont(ofSize: 10)
                    
                    // Hospital logo or name at the top
                    let hospitalName = "MediCare Hospital"
                    let hospitalNameAttributes: [NSAttributedString.Key: Any] = [
                        .font: titleFont,
                        .foregroundColor: UIColor.black
                    ]
                    let hospitalNameSize = hospitalName.size(withAttributes: hospitalNameAttributes)
                    let hospitalNameRect = CGRect(
                        x: (pageWidth - hospitalNameSize.width) / 2,
                        y: 50,
                        width: hospitalNameSize.width,
                        height: hospitalNameSize.height
                    )
                    hospitalName.draw(in: hospitalNameRect, withAttributes: hospitalNameAttributes)
                    
                    // Draw a line under the hospital name
                    context.cgContext.setStrokeColor(UIColor.gray.cgColor)
                    context.cgContext.setLineWidth(1.0)
                    context.cgContext.move(to: CGPoint(x: 72, y: 80))
                    context.cgContext.addLine(to: CGPoint(x: pageWidth - 72, y: 80))
                    context.cgContext.strokePath()
                    
                    // Title
                    let title = "CONSULTATION REPORT"
                    let titleAttributes: [NSAttributedString.Key: Any] = [
                        .font: headerFont,
                        .foregroundColor: UIColor.black
                    ]
                    let titleSize = title.size(withAttributes: titleAttributes)
                    let titleRect = CGRect(
                        x: (pageWidth - titleSize.width) / 2,
                        y: 100,
                        width: titleSize.width,
                        height: titleSize.height
                    )
                    title.draw(in: titleRect, withAttributes: titleAttributes)
                    
                    // Patient information
                    let patientInfoY: CGFloat = 140
                    let leftMargin: CGFloat = 72
                    let rightColumnX: CGFloat = pageWidth / 2 + 20
                    
                    // Patient name
                    "Patient Name:".draw(at: CGPoint(x: leftMargin, y: patientInfoY), withAttributes: [.font: headerFont])
                    patientName.draw(at: CGPoint(x: leftMargin + 120, y: patientInfoY), withAttributes: [.font: regularFont])
                    
                    // Patient ID
                    "Patient ID:".draw(at: CGPoint(x: rightColumnX, y: patientInfoY), withAttributes: [.font: headerFont])
                    patientId.draw(at: CGPoint(x: rightColumnX + 100, y: patientInfoY), withAttributes: [.font: regularFont])
                    
                    // Date
                    "Date:".draw(at: CGPoint(x: leftMargin, y: patientInfoY + 25), withAttributes: [.font: headerFont])
                    formattedDate.draw(at: CGPoint(x: leftMargin + 120, y: patientInfoY + 25), withAttributes: [.font: regularFont])
                    
                    // Appointment ID
                    "Appointment ID:".draw(at: CGPoint(x: rightColumnX, y: patientInfoY + 25), withAttributes: [.font: headerFont])
                    appointmentId.draw(at: CGPoint(x: rightColumnX + 100, y: patientInfoY + 25), withAttributes: [.font: regularFont])
                    
                    // Draw a line under patient info
                    context.cgContext.setStrokeColor(UIColor.gray.cgColor)
                    context.cgContext.setLineWidth(0.5)
                    context.cgContext.move(to: CGPoint(x: leftMargin, y: patientInfoY + 45))
                    context.cgContext.addLine(to: CGPoint(x: pageWidth - leftMargin, y: patientInfoY + 45))
                    context.cgContext.strokePath()
                    
                    // Doctor Notes
                    var yPosition: CGFloat = patientInfoY + 70
                    
                    "DOCTOR NOTES:".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [.font: headerFont])
                    yPosition += 25
                    
                    // Draw multi-line text for doctor notes
                    let notesRect = CGRect(x: leftMargin, y: yPosition, width: pageWidth - (leftMargin * 2), height: 100)
                    drawMultilineText(doctorNotes, in: notesRect, with: regularFont, context: context)
                    
                    yPosition += 120
                    
                    // Prescriptions
                    "PRESCRIPTIONS:".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [.font: headerFont])
                    yPosition += 25
                    
                    // Draw multi-line text for prescriptions
                    let prescriptionsRect = CGRect(x: leftMargin, y: yPosition, width: pageWidth - (leftMargin * 2), height: 100)
                    drawMultilineText(prescriptions, in: prescriptionsRect, with: regularFont, context: context)
                    
                    yPosition += 120
                    
                    // Tests
                    "RECOMMENDED TESTS:".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: [.font: headerFont])
                    yPosition += 25
                    
                    // Draw multi-line text for tests
                    let testsRect = CGRect(x: leftMargin, y: yPosition, width: pageWidth - (leftMargin * 2), height: 100)
                    drawMultilineText(tests, in: testsRect, with: regularFont, context: context)
                    
                    // Footer
                    let footerY = pageHeight - 50
                    
                    // Draw a line above the footer
                    context.cgContext.setStrokeColor(UIColor.gray.cgColor)
                    context.cgContext.setLineWidth(0.5)
                    context.cgContext.move(to: CGPoint(x: leftMargin, y: footerY - 10))
                    context.cgContext.addLine(to: CGPoint(x: pageWidth - leftMargin, y: footerY - 10))
                    context.cgContext.strokePath()
                    
                    // Doctor signature with actual doctor name
                    let signatureText = "Dr. \(doctorName)"
                    signatureText.draw(
                        at: CGPoint(x: leftMargin, y: footerY),
                        withAttributes: [.font: regularFont]
                    )
                    
                    // Page number
                    let pageText = "Page 1 of 1"
                    let pageTextAttributes: [NSAttributedString.Key: Any] = [.font: smallFont]
                    let pageTextSize = pageText.size(withAttributes: pageTextAttributes)
                    pageText.draw(
                        at: CGPoint(x: pageWidth - leftMargin - pageTextSize.width, y: footerY),
                        withAttributes: pageTextAttributes
                    )
                }
                
                DispatchQueue.main.async {
                    completion(fileURL)
                }
            } catch {
                print("Error generating PDF: \(error)")
                // Handle error
            }
        }
    }
    
    private func drawMultilineText(_ text: String, in rect: CGRect, with font: UIFont, context: UIGraphicsPDFRendererContext) {
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)
        
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedText)
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: attributedText.length), path, nil)
        
        context.cgContext.saveGState()
        context.cgContext.translateBy(x: 0, y: rect.origin.y * 2 + rect.size.height)
        context.cgContext.scaleBy(x: 1.0, y: -1.0)
        CTFrameDraw(frame, context.cgContext)
        context.cgContext.restoreGState()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: consultationDate)
    }
}

// PDF Preview View
struct PDFPreviewView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PDFKitView(url: url)
                .edgesIgnoringSafeArea(.bottom)
                .navigationTitle("Consultation PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// Share Sheet for sharing the PDF
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
