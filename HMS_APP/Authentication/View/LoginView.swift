//  LoginView.swift
//  HMS
//
//  Created by rjk on 21/04/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginScreen: View {
    @Environment(\.colorScheme) var colorScheme
    
    var userType: String
    
    init(userType: String) {
        self.userType = userType
    }
    
    @StateObject private var authService = AuthService()
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var navigateToSignup = false
    @State private var navigateTo2FA = false
    @State private var navigateToDashboard = false
    @State private var errorMessage: String? = nil

    private var isFormValid: Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               emailError == nil &&
               passwordError == nil
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("\(userType.capitalized) Login")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(colorScheme == .dark ? Theme.dark.tertiary : Theme.light.tertiary)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading) {
                Text("Email")
                    .foregroundColor(Color.primary)
                    .font(.system(size: 14))
                CustomTextField(
                    placeholder: "Enter your email",
                    isSecure: false,
                    text: $email,
                    errorMessage: emailError
                )
                .onChange(of: email) { _, newValue in
                    validateEmail(newValue)
                }
                .submitLabel(.next)
            }
            
            VStack(alignment: .leading) {
                Text("Password")
                    .foregroundColor(Color.primary)
                    .font(.system(size: 14))
                CustomTextField(
                    placeholder: "Enter your password",
                    isSecure: true,
                    text: $password,
                    errorMessage: passwordError
                )
                .onChange(of: password) { _, newValue in
                    validatePassword(newValue)
                }
                .submitLabel(.go)
            }
            
            HStack {
                Spacer()
                Button(action: {
                    // Handle forgot password
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(colorScheme == .dark ? Theme.dark.tertiary : Theme.light.tertiary)
                        .font(.system(size: 14))
                }
            }
            
            Button(action: {
                Task {
                    await handleLogin()
                }
            }) {
                Text("NEXT")
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isFormValid ? (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary) : Color.blue.opacity(0.3))
                    .cornerRadius(12)
            }
            .disabled(!isFormValid)
            
            HStack {
                Text("Don't Have An Account?")
                    .foregroundColor(Color.primary)
                    .font(.system(size: 14))
                Button(action: {
                    navigateToSignup = true
                }) {
                    Text("Sign Up")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 26)
        .frame(maxHeight: .infinity, alignment: .center)
        .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
        .navigationDestination(isPresented: $navigateToSignup) {
            SignUpScreen(userType: userType)
        }
        .navigationDestination(isPresented: $navigateTo2FA) {
            TwoFAView(isLoginFlow: true, email: email, userType: userType)
        }
        .navigationDestination(isPresented: $navigateToDashboard) {
            getDashboardView()
        }
        .navigationBarBackButtonHidden()
    }

    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = "Email cannot be empty"
        } else if !email.contains("@") {
            emailError = "Email must contain '@'"
        } else {
            emailError = nil
        }
    }

    private func validatePassword(_ password: String) {
        if password.isEmpty {
            passwordError = "Password cannot be empty"
        } else {
            let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
            let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
            let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
            let symbolSet = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?~`")
            let hasSymbol = password.rangeOfCharacter(from: symbolSet) != nil
            
            if !(hasUppercase && hasLowercase && hasNumber && hasSymbol) {
                passwordError = "Password must include uppercase, lowercase, number, and symbol"
            } else {
                passwordError = nil
            }
        }
    }

    private func handleLogin() async {
        authService.email = email
        authService.password = password
        
        do {
            // First check if user exists in Firestore
            if await checkUserExists(email: email) {
                // Then try to login with Appwrite
                try await authService.login()
                
                // If successful, proceed to 2FA
                try await authService.sendEmailOTP()
                navigateTo2FA = true
            } else {
                // No user record exists
                errorMessage = "No \(userType) account found with email: \(email). Please check your user type or sign up first."
            }
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
            // Add additional error logging
            print("Login error details - Email: \(email), UserType: \(userType), Error: \(error)")
        }
    }
    
    // Check if user record exists in Firestore with the given email
    private func checkUserExists(email: String) async -> Bool {
        do {
            let db = Firestore.firestore()
            let collectionName = getCollectionName()
            let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("DEBUG - Login Check:")
            print("- User Type: \(userType)")
            print("- Collection Name: \(collectionName)")
            print("- Normalized Email: \(normalizedEmail)")
            
            let snapshot = try await db.collection(collectionName)
                .whereField("email", isEqualTo: normalizedEmail)
                .limit(to: 1)
                .getDocuments()
            
            let exists = !snapshot.documents.isEmpty
            print("- Query Result: \(exists)")
            if exists {
                print("- Found Document ID: \(snapshot.documents[0].documentID)")
                print("- Document Data: \(snapshot.documents[0].data())")
            }
            
            return exists
        } catch {
            print("DEBUG - Error Details:")
            print("- Error Description: \(error.localizedDescription)")
            print("- User Type: \(userType)")
            print("- Collection: \(getCollectionName())")
            return false
        }
    }
    
    // Get the appropriate Firestore collection name based on user type
    private func getCollectionName() -> String {
        switch userType.lowercased() {
        case "hospital":
            return "hms4_admins"
        case "doctor":
            return "hms4_doctors"
        case "patient":
            return "hms4_patients"
        default:
            return "hms4_users"
        }
    }
    
    // Return the appropriate dashboard view based on user type
    @ViewBuilder
    private func getDashboardView() -> some View {
        switch userType {
        case "hospital":
            HospitalView()
        case "doctor":
            HospitalView()
        case "patient":
            HospitalView()
        default:
            Text("Default Dashboard")
        }
    }
}

#Preview {
    LoginScreen(userType: "hospital")
}
