//
//  ProfileView.swift
//  HMS_Admin
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedTab: Int
    @StateObject private var authService = AuthService()
    @EnvironmentObject var authManager: AuthManager
    @State private var navigateToSignUp = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showNotificationSettings = false
    @State private var showEditProfile = false
    @State private var userName = "John Doe"
    @State private var isDeleting = false
    @State private var showDeletionError = false
    @State private var deletionErrorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background color
                (colorScheme == .dark ? Color(UIColor.systemGray6) : Theme.light.background)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Profile Header Card
                        VStack(spacing: 5) {
                            // Profile Image with Edit Button
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "person")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                
                                // Edit button
                                Button(action: {
                                    showEditProfile = true
                                }) {
                                    Circle()
                                        .fill(Color.blue.opacity(0.8))
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            Image(systemName: "pencil")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                        )
                                }
                                .offset(x: 30, y: 30)
                            }
                            .padding(.bottom, 4)
                            
                            // Name and Role
                            Text(userName)
                                .font(.title3)
                                .fontWeight(.medium)
                                .padding(.top, 8)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            
                            Text("ADMIN")
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5))
                                .cornerRadius(12)
                                
                            if let user = authManager.currentUser, !user.hospitalName.isEmpty && user.hospitalName != "General Hospital" {
                                Text(user.hospitalName)
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal)

                        
                        // General Section
                        SectionHeader(title: "General")
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Menu Items Card
                        VStack(spacing: 0) {
                            // Notification Settings
                            MenuButton(
                                icon: "bell.fill",
                                iconColor: .orange,
                                iconBackground: colorScheme == .dark ? Color.orange.opacity(0.3) : Color.orange.opacity(0.1),
                                title: "Notification Settings"
                            ) {
                                showNotificationSettings = true
                            }
                            
                            // Logout
                            MenuButton(
                                icon: "rectangle.portrait.and.arrow.right",
                                iconColor: .red,
                                iconBackground: colorScheme == .dark ? Color.red.opacity(0.3) : Color.red.opacity(0.1),
                                title: "Logout"
                            ) {
                                Task {
                                    await handleLogout()
                                }
                            }
                            
                            // Delete Account
                            MenuButton(
                                icon: "trash.fill",
                                iconColor: .red,
                                iconBackground: colorScheme == .dark ? Color.red.opacity(0.3) : Color.red.opacity(0.1),
                                title: "Delete Account",
                                isLast: true
                            ) {
                                showDeleteAccountConfirmation = true
                            }
                        }
                        .background(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: $showDeleteAccountConfirmation) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            await deleteAccount()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Error Deleting Account", isPresented: $showDeletionError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deletionErrorMessage)
            }
        }
        .navigationDestination(isPresented: $navigateToSignUp) {
            SignUpScreen(userType: "Doctor")
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(userName: $userName)
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsView()
        }
        .onAppear {
            // First try to get name from freshly saved UserDefaults
            if let savedName = UserDefaults.standard.string(forKey: "tempUserName"),
               !savedName.isEmpty && savedName != "Hospital Admin" {
                userName = savedName
            }
            // Then check the AuthManager
            else if let user = authManager.currentUser,
                    !user.name.isEmpty && user.name != "Hospital Admin" {
                userName = user.name
            }
            // Otherwise use a realistic default if nothing else is available
            else if userName == "John Doe" || userName == "Hospital Admin" {
                // Check if we're in signup flow by looking for email
                if let email = UserDefaults.standard.string(forKey: "tempUserEmail"),
                   !email.isEmpty {
                    // Extract name from email (before @ symbol)
                    if let nameFromEmail = email.split(separator: "@").first {
                        userName = String(nameFromEmail).capitalized
                    }
                }
            }
        }
    }
    
    private func handleLogout() async {
        await authService.logout()
        navigateToSignUp = true
    }
    
    private func deleteAccount() async {
        isDeleting = true
        
        // Get user email - first try from authManager, then fallback to Firebase Auth
        var userEmail = ""
        if let currentUser = authManager.currentUser {
            userEmail = currentUser.email
        } else if let user = Auth.auth().currentUser, let email = user.email {
            userEmail = email
        }
        
        print("🔍 Attempting to delete account with email: \(userEmail)")
        
        // FOCUS: Delete user data from Firestore first using email
        if !userEmail.isEmpty {
            do {
                // Get the Firestore instance
                let db = Firestore.firestore()
                
                // IMPORTANT: Delete from hms4_admins collection
                print("🔄 Searching for admin accounts with email: \(userEmail) in hms4_admins")
                let adminQuerySnapshot = try await db.collection("hms4_admins")
                    .whereField("email", isEqualTo: userEmail)
                    .getDocuments()
                
                if adminQuerySnapshot.documents.isEmpty {
                    print("⚠️ No admin documents found with email: \(userEmail) in hms4_admins collection")
                } else {
                    print("✅ Found \(adminQuerySnapshot.documents.count) documents to delete")
                    
                    // Delete each matching document
                    for document in adminQuerySnapshot.documents {
                        let docId = document.documentID
                        print("🗑️ Deleting admin document with ID: \(docId)")
                        
                        try await db.collection("hms4_admins").document(docId).delete()
                        
                        // Verify deletion
                        let verifyDoc = try? await db.collection("hms4_admins").document(docId).getDocument()
                        if verifyDoc == nil || !verifyDoc!.exists {
                            print("✅ Successfully deleted document \(docId) from hms4_admins")
                        } else {
                            print("⚠️ Failed to delete document \(docId) from hms4_admins")
                        }
                    }
                }
                
                // If we get here, the database deletion part was successful
                print("🎉 Database deletion process completed")
                
                // Now proceed with the rest of account deletion
                await completeAccountDeletion()
                
            } catch {
                print("❌ Error deleting from Firestore: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
                
                // Despite Firestore error, try to proceed with account deletion
                await completeAccountDeletion()
            }
        } else {
            print("⚠️ No email found for current user - cannot delete from database")
            // Still try to delete the account authentication
            await completeAccountDeletion()
        }
    }
    
    // Helper method to complete the account deletion process
    private func completeAccountDeletion() async {
        guard let user = Auth.auth().currentUser else {
            isDeleting = false
            navigateToSignUp = true
            return
        }
        
        // Delete Appwrite account
        do {
            try await authService.deleteAccount()
            print("✅ Appwrite account deletion attempted")
        } catch {
            print("❌ Error with Appwrite account: \(error.localizedDescription)")
            // Continue anyway
        }
        
        // Delete Firebase Authentication account
        do {
            try await user.delete()
            print("✅ Firebase Authentication account deleted successfully")
            
            // Clear local data and navigate to sign up
            await authService.logout()
            authManager.logout()
            UserDefaults.standard.removeObject(forKey: "tempUserName")
            UserDefaults.standard.removeObject(forKey: "tempUserEmail")
            UserDefaults.standard.removeObject(forKey: "userId")
            
            isDeleting = false
            navigateToSignUp = true
        } catch {
            isDeleting = false
            print("❌ Error deleting Firebase Authentication account: \(error.localizedDescription)")
            deletionErrorMessage = "Failed to delete account: \(error.localizedDescription)"
            showDeletionError = true
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
            Spacer()
        }
    }
}

struct MenuButton: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    var isLast: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 16))
                }
                
                // Title
                Text(title)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .padding(.leading, 12)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(colorScheme == .dark ? .gray.opacity(0.7) : .gray)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
        
        if !isLast {
            Divider()
                .padding(.leading, 64)
                .opacity(colorScheme == .dark ? 0.3 : 1.0)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Binding var userName: String
    @State private var newUserName: String = ""
    @State private var email: String = ""
    @State private var hospitalName: String = ""
    @State private var showImagePicker = false
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "person")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Circle()
                            .fill(Color.blue.opacity(0.8))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                    }
                    .offset(x: 30, y: 30)
                }
                .padding(.top, 30)
                
                // Form fields
                VStack(spacing: 20) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                        
                        TextField("Enter your name", text: $newUserName)
                            .padding()
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                        
                        TextField("Enter your email", text: $email)
                            .padding()
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    // Hospital Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hospital Name")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                        
                        TextField("Enter hospital name", text: $hospitalName)
                            .padding()
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer()
                
                // Save Button
                Button(action: {
                    if !newUserName.isEmpty {
                        userName = newUserName
                        // Save name to AuthManager and Firestore
                        authManager.updateUserInfo(
                            name: newUserName,
                            email: email,
                            role: "Admin",
                            hospitalName: hospitalName
                        )
                    }
                    dismiss()
                }) {
                    Text("Save Changes")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialize with current user data
                if let user = authManager.currentUser {
                    newUserName = user.name
                    email = user.email
                    hospitalName = user.hospitalName
                } else {
                    newUserName = userName
                }
            }
            .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
        }
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var pushNotifications = true
    @State private var emailNotifications = true
    @State private var appointmentReminders = true
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Notification Preferences"),
                        footer: Text("Control which notifications you receive from the app")
                            .foregroundColor(colorScheme == .dark ? .gray : .gray)) {
                    Toggle("Push Notifications", isOn: $pushNotifications)
                        .tint(.blue)
                    Toggle("Email Notifications", isOn: $emailNotifications)
                        .tint(.blue)
                    Toggle("Appointment Reminders", isOn: $appointmentReminders)
                        .tint(.blue)
                }
            }
            .navigationTitle("Notifications")
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

