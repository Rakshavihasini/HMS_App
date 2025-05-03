import Foundation

struct MedicalRecord: Identifiable {
    let id: String
    let fileName: String
    let fileType: String
    let downloadURL: String
    let uploadDate: Date
    
    var fileExtension: String {
        let components = fileName.components(separatedBy: ".")
        return components.count > 1 ? components.last!.lowercased() : ""
    }
    
    var isPDF: Bool {
        fileExtension == "pdf"
    }
    
    var isImage: Bool {
        ["jpg", "jpeg", "png", "heic"].contains(fileExtension)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: uploadDate)
    }
} 