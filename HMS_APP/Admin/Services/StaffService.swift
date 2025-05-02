//
//  StaffService.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 01/05/25.
//


//
//  StaffService.swift
//  HMS_Admin
//
//  Created by admin49 on 25/04/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

class StaffService: ObservableObject {
    @Published var staffMembers: [Staff] = []
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let dbName = "hms4"
    
    // Fetch all staff members
    func fetchStaff() {
        db.collection("\(dbName)_staff").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error fetching staff: \(error)")
                return
            }
            
            if let snapshot = snapshot {
                print("✅ Total Staff: \(snapshot.documents.count)")
                var fetchedStaff: [Staff] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    
                    // Parse date fields
                    var dateOfBirth: Date? = nil
                    if let dobTimestamp = data["dateOfBirth"] as? Timestamp {
                        dateOfBirth = dobTimestamp.dateValue()
                    }
                    
                    var joinDate: Date? = nil
                    if let joinTimestamp = data["joinDate"] as? Timestamp {
                        joinDate = joinTimestamp.dateValue()
                    }
                    
                    // Create staff from document data
                    let staff = Staff(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        dateOfBirth: dateOfBirth,
                        joinDate: joinDate,
                        educationalQualification: data["educationalQualification"] as? String,
                        certificates: data["certificates"] as? [String],
                        staffRole: data["staffRole"] as? String
                    )
                    
                    fetchedStaff.append(staff)
                }
                
                DispatchQueue.main.async {
                    self?.staffMembers = fetchedStaff
                    print("✅ Fetched \(fetchedStaff.count) staff members")
                }
            }
        }
    }
    
    // Add a staff member
    func addStaff(_ staff: Staff, certificateFiles: [URL] = [], completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = storage.reference().child("\(dbName)/staff")
        var uploadedCertificateURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        
        // Upload certificates to Firebase Storage
        for certificateURL in certificateFiles {
            guard let fileName = certificateURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                continue
            }
            let fileRef = storageRef.child(fileName)
            dispatchGroup.enter()
            
            // Read file data from URL
            do {
                let fileData = try Data(contentsOf: certificateURL)
                fileRef.putData(fileData, metadata: nil) { metadata, error in
                    if let error = error {
                        print("❌ Error uploading certificate \(fileName): \(error)")
                        dispatchGroup.leave()
                        return
                    }
                    fileRef.downloadURL { url, error in
                        if let url = url {
                            uploadedCertificateURLs.append(url.absoluteString)
                        } else if let error = error {
                            print("❌ Error getting download URL for \(fileName): \(error)")
                        }
                        dispatchGroup.leave()
                    }
                }
            } catch {
                print("❌ Error reading file \(fileName): \(error)")
                dispatchGroup.leave()
            }
        }
        
        // After all uploads are complete, save staff data to Firestore
        dispatchGroup.notify(queue: .main) {
            let staffData: [String: Any] = [
                "uuid": staff.id,
                "name": staff.name,
                "dateOfBirth": staff.dateOfBirth as Any,
                "joinDate": staff.joinDate as Any,
                "educationalQualification": staff.educationalQualification as Any,
                "certificates": staff.certificates as Any,
                "staffRole": staff.staffRole as Any,
                "certificateURLs": uploadedCertificateURLs,
                "createdAt": Timestamp(date: Date())
            ]
            
            self.db.collection("\(self.dbName)_staff").document(staff.id).setData(staffData) { error in
                if let error = error {
                    print("❌ Error saving staff to Firestore: \(error)")
                    completion(.failure(error))
                } else {
                    print("✅ Staff saved successfully")
                    completion(.success(()))
                }
            }
        }
    }
}
