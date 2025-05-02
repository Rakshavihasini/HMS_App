//  SignUpView.swift
//  HMS
//
//  Created by rjk on 21/04/25.
//

import SwiftUI
import FirebaseFirestore

struct SignUpScreen: View {
    @Environment(\.colorScheme) var colorScheme
    
    var userType: String
    
    init(userType: String) {
        self.userType = userType
    }
    
    @StateObject private var authService = AuthService()
    @EnvironmentObject var authManager: AuthManager
    @State private var userName: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @State private var userNameError: String? = nil
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    @State private var navigateToLogIn = false
    @State private var navigateTo2FA = false
    @State private var errorMessage: String? = nil

    private var isFormValid: Bool {
        return !userName.isEmpty &&
               !name.isEmpty &&
               !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               userNameError == nil &&
               nameError == nil &&
               emailError == nil &&
               passwordError == nil &&
               confirmPasswordError == nil
    }

    var body: some View {
        let isDark = colorScheme == .dark
        
        VStack(spacing: 20) {
            Text("\(userType.capitalized) Sign Up")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isDark ? Theme.dark.tertiary : Theme.light.tertiary)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading) {
                Text("User Name")
                    .foregroundColor(isDark ? .white : .black)
                    .font(.system(size: 14))
                CustomTextField(
                    placeholder: "Enter your user name",
                    isSecure: false,
                    text: $userName,
                    errorMessage: userNameError
                )
                .onChange(of: userName) { validateUserName(userName) }
            }
            
            VStack(alignment: .leading) {
                Text("Name")
                    .foregroundColor(isDark ? .white : .black)
                    .font(.system(size: 14))
                CustomTextField(
                    placeholder: "Enter your name",
                    isSecure: false,
                    text: $name,
                    errorMessage: nameError
                )
                .onChange(of: name) { validateName(name) }
            }
            
            VStack(alignment: .leading) {
                Text("Email")
                    .foregroundColor(isDark ? .white : .black)
                    .font(.system(size: 14))
                CustomTextField(
                    placeholder: "Enter your email",
                    isSecure: false,
                    text: $email,
                    errorMessage: emailError
                )
                .onChange(of: email) { validateEmail(email) }
            }
            
            VStack(alignment: .leading) {
                Text("Password")
                    .foregroundColor(isDark ? .white : .black)
                    .font(.system(size: 14))
                CustomTextField(
                    placeholder: "Enter your password",
                    isSecure: true,
                    text: $password,
                    errorMessage: passwordError
                )
                .onChange(of: password) { validatePassword(password) }
            }
            
            VStack(alignment: .leading) {
                Text("Confirm Password")
                    .foregroundColor(isDark ? .white : .black)
                    .font(.system(size: 14))
                CustomTextField(
                    placeholder: "Confirm your password",
                    isSecure: true,
                    text: $confirmPassword,
                    errorMessage: confirmPasswordError
                )
                .onChange(of: confirmPassword) { validateConfirmPassword(confirmPassword) }
            }
            
            Button(action: {
                Task {
                    await handleSignUp()
                }
            }) {
                Text("NEXT")
                    .fontWeight(.bold)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(isFormValid ? (isDark ? Theme.dark.primary : Theme.light.primary) : Color.blue.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.top, 30)
            .disabled(!isFormValid)
            
            HStack {
                Text("Already Have An Account?")
                    .foregroundColor(isDark ? .white : .black)
                    .font(.system(size: 14))
                Button(action: {
                    navigateToLogIn = true
                }) {
                    Text("Login")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            }
        }
        .padding([.leading, .trailing], 26)
        .frame(maxHeight: .infinity, alignment: .center)
        .background(isDark ? Theme.dark.background : Theme.light.background)
        .navigationDestination(isPresented: $navigateToLogIn) {
            LoginScreen(userType: userType)
        }
        .navigationDestination(isPresented: $navigateTo2FA) {
            TwoFAView(isLoginFlow: false, email: email, userType: userType)
                .environmentObject(authManager)
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Validation Methods
    private func validateUserName(_ userName: String) {
        userNameError = userName.isEmpty ? "Username cannot be empty" : nil
    }

    private func validateName(_ name: String) {
        nameError = name.isEmpty ? "Name cannot be empty" : nil
    }

    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = "Email cannot be empty"
        } else if !email.contains("@") {
            emailError = "Invalid email format"
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

    private func validateConfirmPassword(_ confirmPassword: String) {
        confirmPasswordError = confirmPassword != password ? "Passwords do not match" : nil
    }

    // MARK: - Sign Up Handler
    private func handleSignUp() async {
        authService.name = name
        authService.email = email
        authService.password = password
        
        do {
            try await authService.register()
            
            // Store user data in the appropriate collection based on userType
            try await storeUserData()
            
            // All users proceed to 2FA regardless of type
            try await authService.sendEmailOTP()
            navigateTo2FA = true
        } catch {
            errorMessage = "Registration failed: \(error.localizedDescription)"
        }
    }
    
    // Store user data in Firestore based on user type
    private func storeUserData() async throws {
        let db = Firestore.firestore()
        let collectionName = getCollectionName()
        
        let userData: [String: Any] = [
            "userName": userName,
            "name": name,
            "email": email,
            "createdAt": Date(),
            "userType": userType
        ]
        
        try await db.collection(collectionName).document().setData(userData)
    }
    
    // Get the appropriate Firestore collection name based on user type
    private func getCollectionName() -> String {
        switch userType {
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
}
