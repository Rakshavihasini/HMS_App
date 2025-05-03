import Foundation
import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseCore

class FileUploadService: ObservableObject {
    @Published var isUploading = false
    @Published var progress: Double = 0
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    private let dbName = "hms4" // Match the database name from FirestoreService
    
    func uploadFile(data: Data, fileName: String, patientId: String, fileType: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("Starting upload process for file: \(fileName)")
        print("Patient ID: \(patientId)")
        print("File type: \(fileType)")
        print("File size: \(data.count) bytes")
        
        isUploading = true
        
        // Create a unique filename with timestamp to avoid conflicts
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "\(timestamp)_\(fileName)"
        print("Generated unique filename: \(uniqueFileName)")
        
        // Create a storage reference with proper path structure
        let storageRef = storage.reference()
            .child("\(dbName)")
            .child("patients")
            .child(patientId)
            .child("medical_records")
            .child(uniqueFileName)
        
        print("Storage path: \(storageRef.fullPath)")
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = fileType
        
        // Create the upload task
        let uploadTask = storageRef.putData(data, metadata: metadata) { metadata, error in
            print("Upload task completed")
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                self.isUploading = false
                completion(.failure(error))
                return
            }
            
            print("Upload successful, getting download URL")
            // Once uploaded, get the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Download URL error: \(error.localizedDescription)")
                    self.isUploading = false
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    print("Failed to get download URL")
                    self.isUploading = false
                    completion(.failure(NSError(domain: "FileUploadService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                print("Got download URL: \(downloadURL)")
                print("Saving metadata to Firestore")
                
                // Save record metadata to Firestore
                self.saveRecordMetadata(patientId: patientId, fileName: uniqueFileName, fileType: fileType, downloadURL: downloadURL) { result in
                    self.isUploading = false
                    switch result {
                    case .success:
                        print("Metadata saved successfully")
                        completion(.success(downloadURL))
                    case .failure(let error):
                        print("Metadata save error: \(error.localizedDescription)")
                        // If metadata save fails, try to delete the uploaded file
                        storageRef.delete { deleteError in
                            if let deleteError = deleteError {
                                print("Warning: Failed to delete file after metadata save failure: \(deleteError.localizedDescription)")
                            }
                        }
                        completion(.failure(error))
                    }
                }
            }
        }
        
        // Observe progress
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            DispatchQueue.main.async {
                self.progress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                print("Upload progress: \(Int(self.progress * 100))%")
            }
        }
    }
    
    private func saveRecordMetadata(patientId: String, fileName: String, fileType: String, downloadURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Saving record metadata to Firestore")
        print("Collection path: \(dbName)_patients/\(patientId)/medical_records")
        
        let record: [String: Any] = [
            "fileName": fileName,
            "fileType": fileType,
            "downloadURL": downloadURL,
            "uploadDate": Timestamp(date: Date())
        ]
        
        db.collection("\(dbName)_patients").document(patientId).collection("medical_records").addDocument(data: record) { error in
            if let error = error {
                print("Firestore save error: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("Firestore save successful")
                completion(.success(()))
            }
        }
    }
    
    func getPatientRecords(patientId: String, completion: @escaping (Result<[MedicalRecord], Error>) -> Void) {
        print("Fetching records for patient: \(patientId)")
        
        db.collection("\(dbName)_patients").document(patientId).collection("medical_records")
            .order(by: "uploadDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Record fetch error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    completion(.success([]))
                    return
                }
                
                print("Found \(documents.count) records")
                let records = documents.compactMap { document -> MedicalRecord? in
                    let data = document.data()
                    guard 
                        let fileName = data["fileName"] as? String,
                        let fileType = data["fileType"] as? String,
                        let downloadURL = data["downloadURL"] as? String,
                        let uploadDate = data["uploadDate"] as? Timestamp
                    else {
                        print("Failed to parse document: \(document.documentID)")
                        return nil
                    }
                    
                    print("Record found: \(fileName) with URL: \(downloadURL)")
                    
                    return MedicalRecord(
                        id: document.documentID,
                        fileName: fileName,
                        fileType: fileType,
                        downloadURL: downloadURL,
                        uploadDate: uploadDate.dateValue()
                    )
                }
                
                print("Successfully parsed \(records.count) records")
                completion(.success(records))
            }
    }
    
    // Helper for refreshing Firebase Storage URLs
    func getRefreshedURL(for originalURL: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("Attempting to refresh URL: \(originalURL)")
        
        // Parse original URL to extract storage path
        guard let url = URL(string: originalURL),
              url.absoluteString.contains("firebase") else {
            print("Not a Firebase URL or invalid URL format")
            completion(.success(originalURL)) // Just return the original non-Firebase URL
            return
        }
        
        // Try to extract the path from the URL
        let pathComponents = url.pathComponents
        if pathComponents.count < 3 {
            print("URL doesn't contain enough path components")
            completion(.failure(NSError(domain: "FileUploadService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid Firebase Storage URL format"])))
            return
        }
        
        // Get the storage reference from the URL path
        // This is a simplified example - you may need to adjust based on your URL structure
        // Example URL format: https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/path%2Fto%2Ffile.pdf
        
        print("Requesting fresh download URL")
        // For now, return the original URL
        completion(.success(originalURL))
    }
} 