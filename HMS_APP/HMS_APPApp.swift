//
//  HMS_APPApp.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 30/04/25.
//

import SwiftUI
import FirebaseCore

@main
struct HMS_APPApp: App {
    init() {
        FirebaseApp.configure()
    }
    @StateObject private var authManager = AuthManager()
    @StateObject private var doctorManager = DoctorManager()
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                UserSelectionView()
            }
            .environmentObject(authManager)
            .environmentObject(doctorManager)
        }
    }
}
