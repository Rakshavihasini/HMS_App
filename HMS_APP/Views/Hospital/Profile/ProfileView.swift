//import SwiftUI
//
//struct ProfileView: View {
//    @Binding var selectedTab: Int
//    @Environment(\.colorScheme) var colorScheme
//    @EnvironmentObject var authManager: AuthManager
//    
//    var body: some View {
//        NavigationView {
//            List {
//                // Profile Header
//                Section {
//                    HStack(spacing: 16) {
//                        Circle()
//                            .fill(Color.blue.opacity(0.1))
//                            .frame(width: 80, height: 80)
//                            .overlay(
//                                Text("H")
//                                    .font(.title)
//                                    .foregroundColor(.blue)
//                            )
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(authManager.userName)
//                                .font(.headline)
//                            Text(authManager.userEmail)
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                            Text("Hospital Admin")
//                                .font(.caption)
//                                .foregroundColor(.blue)
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//                
//                // Account Settings
//                Section("Account") {
//                    NavigationLink(destination: Text("Edit Profile")) {
//                        SettingsRow(icon: "person.fill", title: "Edit Profile", color: .blue)
//                    }
//                    
//                    NavigationLink(destination: Text("Security Settings")) {
//                        SettingsRow(icon: "lock.fill", title: "Security", color: .green)
//                    }
//                    
//                    NavigationLink(destination: Text("Notifications")) {
//                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
//                    }
//                }
//                
//                // App Settings
//                Section("Preferences") {
//                    NavigationLink(destination: Text("Language Settings")) {
//                        SettingsRow(icon: "globe", title: "Language", color: .purple)
//                    }
//                    
//                    NavigationLink(destination: Text("Appearance Settings")) {
//                        SettingsRow(icon: "paintbrush.fill", title: "Appearance", color: .pink)
//                    }
//                }
//                
//                // Support & About
//                Section("Support") {
//                    NavigationLink(destination: Text("Help Center")) {
//                        SettingsRow(icon: "questionmark.circle.fill", title: "Help Center", color: .teal)
//                    }
//                    
//                    NavigationLink(destination: Text("About HMS")) {
//                        SettingsRow(icon: "info.circle.fill", title: "About", color: .indigo)
//                    }
//                }
//                
//                // Logout
//                Section {
//                    Button(action: {
//                        authManager.logout()
//                    }) {
//                        HStack {
//                            Image(systemName: "rectangle.portrait.and.arrow.right")
//                                .foregroundColor(.red)
//                            Text("Logout")
//                                .foregroundColor(.red)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Profile")
//            .listStyle(InsetGroupedListStyle())
//        }
//    }
//}
//
//struct SettingsRow: View {
//    let icon: String
//    let title: String
//    let color: Color
//    
//    var body: some View {
//        HStack {
//            Image(systemName: icon)
//                .foregroundColor(color)
//                .frame(width: 24)
//            Text(title)
//        }
//    }
//} 
