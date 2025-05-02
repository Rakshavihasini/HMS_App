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
    
    var body: some View {
        NavigationStack {
            TabView {
                PatientDashboardView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                DoctorsView()
                    .tabItem {
                        Label("Doctors", systemImage: "stethoscope")
                    }
                
                MedicalRecordsView()
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
