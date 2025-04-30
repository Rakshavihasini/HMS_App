//
//  AuthManager.swift
//  MediCareManager
//
//  Created by s1834 on 18/04/25.
//

import Foundation

struct UserInfo {
    let id: String
    let name: String
    let email: String
    let role: String
    let hospitalName: String
    
    // Initialize from Admin model
    init(from admin: Admin) {
        self.id = admin.id
        self.name = admin.name
        self.email = admin.email
        self.role = admin.role
        self.hospitalName = admin.hospitalName
    }
    
    // Default initialization
    init(id: String, name: String, email: String, role: String = "Admin", hospitalName: String = "General Hospital") {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.hospitalName = hospitalName
    }
}

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var currentUserID: String
    @Published var currentUser: UserInfo?
    private let firestoreService = AdminFirestoreService.shared
    
    init() {
        // Check if user is logged in from UserDefaults
        if let userId = UserDefaults.standard.string(forKey: "userId"), !userId.isEmpty {
            self.isLoggedIn = true
            self.currentUserID = userId
            // Try to load user info
            self.currentUser = loadUserInfoFromDefaults()
            
            // Try to fetch the latest user info from Firestore
            Task {
                await fetchUserFromFirestore()
            }
        } else {
            self.isLoggedIn = false
            self.currentUserID = ""
            self.currentUser = nil
        }
    }
    
    // Login functionality
    func login(userId: String, userName: String = "", userEmail: String = "") {
        isLoggedIn = true
        currentUserID = userId
        UserDefaults.standard.set(userId, forKey: "userId")
        
        // Try to load existing user data
        currentUser = loadUserInfoFromDefaults()
        
        // If we have name/email from the login process, use those
        if !userName.isEmpty || !userEmail.isEmpty {
            let name = userName.isEmpty ? (currentUser?.name ?? "") : userName
            let email = userEmail.isEmpty ? (currentUser?.email ?? "") : userEmail
            let role = currentUser?.role ?? "Admin"
            let hospitalName = currentUser?.hospitalName ?? "General Hospital"
            
            currentUser = UserInfo(id: userId, name: name, email: email, role: role, hospitalName: hospitalName)
            saveUserInfoToDefaults()
        }
        
        // Fetch latest data from Firestore
        Task {
            await fetchUserFromFirestore()
        }
    }
    
    // Logout functionality
    func logout() {
        isLoggedIn = false
        currentUserID = ""
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userRole")
        UserDefaults.standard.removeObject(forKey: "userHospitalName")
    }
    
    // Update user info
    func updateUserInfo(name: String, email: String = "", role: String = "Admin", hospitalName: String = "General Hospital") {
        // Update local state
        currentUser = UserInfo(id: currentUserID, name: name, email: email, role: role, hospitalName: hospitalName)
        saveUserInfoToDefaults()
        
        // Update Firestore
        Task {
            try? await firestoreService.getOrCreateAdmin(
                userId: currentUserID,
                name: name,
                email: email,
                role: role,
                hospitalName: hospitalName
            )
            
            // If the admin already exists, update the fields
            if name != "" {
                try? await firestoreService.updateAdmin(userId: currentUserID, updatedFields: ["name": name])
            }
            
            if email != "" {
                try? await firestoreService.updateAdmin(userId: currentUserID, updatedFields: ["email": email])
            }
            
            // Update last active time
            try? await firestoreService.updateLastActive(userId: currentUserID)
        }
    }
    
    // Fetch user info from Firestore
    @MainActor
    private func fetchUserFromFirestore() async {
        do {
            if let admin = try? await firestoreService.getAdmin(userId: currentUserID) {
                // Only update with data from Firestore if it's meaningful
                if !admin.name.isEmpty && admin.name != "Hospital Admin" {
                    self.currentUser = UserInfo(from: admin)
                    saveUserInfoToDefaults()
                }
            } else if let email = UserDefaults.standard.string(forKey: "userEmail"), 
                      let name = UserDefaults.standard.string(forKey: "userName"),
                      !name.isEmpty && name != "Hospital Admin" {
                // Create new admin if none exists but we have some real data
                let _ = try? await firestoreService.getOrCreateAdmin(
                    userId: currentUserID,
                    name: name,
                    email: email
                )
            } else if let authService = try? AuthService(), !authService.name.isEmpty {
                // Try to use name from the auth service if available
                let admin = try? await firestoreService.getOrCreateAdmin(
                    userId: currentUserID,
                    name: authService.name, 
                    email: authService.email
                )
                
                if let admin = admin {
                    self.currentUser = UserInfo(from: admin)
                    saveUserInfoToDefaults()
                }
            }
            // Do not create default placeholder admin if we can't find real data
        } catch {
            print("Error fetching admin data: \(error.localizedDescription)")
        }
    }
    
    // Save user info to UserDefaults
    private func saveUserInfoToDefaults() {
        guard let user = currentUser else { return }
        UserDefaults.standard.set(user.name, forKey: "userName")
        UserDefaults.standard.set(user.email, forKey: "userEmail")
        UserDefaults.standard.set(user.role, forKey: "userRole")
        UserDefaults.standard.set(user.hospitalName, forKey: "userHospitalName")
    }
    
    // Load user info from UserDefaults
    private func loadUserInfoFromDefaults() -> UserInfo? {
        guard !currentUserID.isEmpty else { return nil }
        
        let name = UserDefaults.standard.string(forKey: "userName") ?? "Hospital Admin"
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let role = UserDefaults.standard.string(forKey: "userRole") ?? "Admin"
        let hospitalName = UserDefaults.standard.string(forKey: "userHospitalName") ?? "General Hospital"
        
        return UserInfo(id: currentUserID, name: name, email: email, role: role, hospitalName: hospitalName)
    }
}
