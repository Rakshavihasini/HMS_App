//
//  PatientHomeView.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//



import SwiftUI

struct PatientHomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var appointmentManager = AppointmentManager()
    @State private var userId = UserDefaults.standard.string(forKey: "userId")
    
    var body: some View {
        NavigationStack {
            TabView {
                PatientDashboardView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                DoctorsView()
                    .navigationBarHidden(true)
                    .navigationBarBackButtonHidden(true)
                    .tabItem {
                        Label("Doctors", systemImage: "stethoscope")
                    }
                
                PatientDocumentsView(patientId:userId!)
                    .tabItem {
                        Label("Records", systemImage: "folder.fill")
                    }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PatientProfileButton()
                }
            }
            .environmentObject(appointmentManager)
            .withDynamicTheme()
        }
    }
}

struct PatientProfileButton: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationLink(destination: PatientProfileView()) {
            Image(systemName: "person.crop.circle")
                .imageScale(.large)
        }
    }
}
