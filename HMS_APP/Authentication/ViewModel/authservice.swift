//
//  authservice.swift
//  HMS
//
//  Created by admin49 on 23/04/25.
//

import Appwrite
import Foundation

// Singleton Client instance
class AppwriteService {
    static let shared = AppwriteService()

    let client: Client
    let account: Account

    private init() {
        self.client = Client()
            .setEndpoint("https://cloud.appwrite.io/v1")
            .setProject("67a78ee80034a4cecd30")

        self.account = Account(client)
    }
}

@MainActor
class AuthService: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var userId: String = ""

    private let appwrite = AppwriteService.shared
    
    init() {
        // Try to load name and email from UserDefaults
        self.name = UserDefaults.standard.string(forKey: "tempUserName") ?? ""
        self.email = UserDefaults.standard.string(forKey: "tempUserEmail") ?? ""
    }

    func register() async throws {
        do {
            let user = try await appwrite.account.create(
                userId: UUID().uuidString,
                email: email,
                password: password,
                name: name
            )
            userId = user.id
            print(userId)
            UserDefaults.standard.set(userId, forKey: "userId")
            
            // Save name and email to UserDefaults
            UserDefaults.standard.set(name, forKey: "tempUserName")
            UserDefaults.standard.set(email, forKey: "tempUserEmail")
        } catch {
            print("Registration failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func sendEmailOTP() async throws {
        do {
            let sessionToken = try await appwrite.account.createEmailToken(
                userId: userId.isEmpty ? ID.unique() : userId,
                email: email
            )
            userId = sessionToken.userId
            UserDefaults.standard.set(userId, forKey: "userId")
            
            // Save name and email to UserDefaults again to be safe
            UserDefaults.standard.set(name, forKey: "tempUserName")
            UserDefaults.standard.set(email, forKey: "tempUserEmail")
        } catch {
            print("Failed to send OTP: \(error.localizedDescription)")
            throw error
        }
    }
    
    func verifyOTP(secret: String) async throws {
        print(userId)
        do {
            try? await appwrite.account.deleteSession(sessionId: "current")
            
            let session = try await appwrite.account.createSession(
                userId: UserDefaults.standard.string(forKey: "userId")!,
                secret: secret
            )
            UserDefaults.standard.set(session.userId, forKey: "userId")
        } catch {
            print("OTP verification failed: \(error.localizedDescription)")
            throw error
        }
    }

    func login() async throws {
        do {
            try? await appwrite.account.deleteSession(sessionId: "current")
            
            let user = try await appwrite.account.createEmailPasswordSession(
                email: email,
                password: password
            )

            if let storedUserId = UserDefaults.standard.string(forKey: "userId")
            {
                if storedUserId != user.userId {
                    UserDefaults.standard.set(user.userId, forKey: "userId")
                    print("User ID updated to \(user.userId)")
                }
            } else {
                UserDefaults.standard.set(user.userId, forKey: "userId")
                print("User ID saved: \(user.userId)")
            }
            
            // Save email for later use
            UserDefaults.standard.set(email, forKey: "tempUserEmail")
            
            // Try to get current user details
            do {
                let account = try await appwrite.account.get()
                self.name = account.name
                UserDefaults.standard.set(account.name, forKey: "tempUserName")
            } catch {
                print("Failed to get account details: \(error.localizedDescription)")
            }

        } catch {
            print("Login failed: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteUserAccount() async throws {
        let userDefaults = UserDefaults.standard
        let storedUserId = userDefaults.string(forKey: "userID")
        do {
            let functions = Functions(appwrite.client)

            let execution = try await functions.createExecution(
                functionId: "680f0b0a001c9f181d9f",
                body: """
                {
                    "userId": "\(storedUserId!)"
                }
                """,
                async: false,
                method: .pOST
            )

            print("Delete account execution: \(execution.status)")
            
            self.name = ""
            self.email = ""
            self.password = ""
            self.userId = ""
            
            UserDefaults.standard.removeObject(forKey: "status")
            UserDefaults.standard.removeObject(forKey: "userId")
            UserDefaults.standard.removeObject(forKey: "tempUserName")
            UserDefaults.standard.removeObject(forKey: "tempUserEmail")
        } catch {
            print("Failed to delete account: \(error.localizedDescription)")
            throw error
        }
    }
    
    func logout() async {
        do {
            try await appwrite.account.deleteSession(sessionId: "current")
            
            // Clear all user-related data
            UserDefaults.standard.removeObject(forKey: "userId")
            UserDefaults.standard.removeObject(forKey: "tempUserName")
            UserDefaults.standard.removeObject(forKey: "tempUserEmail")
            
            // Reset current properties
            self.name = ""
            self.email = ""
            self.password = ""
            self.userId = ""
            
            print("Successfully logged out.")
        } catch {
            print("Logout failed: \(error.localizedDescription)")
        }
    }
}
