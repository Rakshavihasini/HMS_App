//
//  DoctorTabView.swift
//  HMS_APP
//
//  Created by Rudra Pruthi on 02/05/25.
//


import SwiftUI
import Firebase
import FirebaseFirestore

struct DoctorTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var doctorManager: DoctorManager
    @State private var selectedIndex: Int = 0
    @State private var selectedTab: String = "Upcoming" // for Dashboard's capsule tabs
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {                
                // Switch between doctor screens
                ZStack {
                    switch selectedIndex {
                    case 0:
                        DashboardContent(selectedTab: $selectedTab)
                            .environmentObject(doctorManager)
                    case 1:
                        // Use doctor data from DoctorManager when available
                        if let doctor = doctorManager.currentDoctor {
                            DoctorSlotManagerView(doctor: doctor)
                        } else {
                            DoctorSlotManagerView()
                        }
                    case 2:
                        PatientsListView()
                    default:
                        DashboardContent(selectedTab: $selectedTab)
                            .environmentObject(doctorManager)
                    }
                }
                
                Divider()
                
                // Reusable tab bar
                DoctorTabBar(selectedIndex: $selectedIndex)
            }
            .background(theme.background)
            .onAppear {
                Task {
                    await doctorManager.fetchCurrentUserInfo()
                }
            }
        }
    }
}

struct DoctorTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedIndex: Int
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            TabItem(image: "house", title: "Dashboard", isSelected: selectedIndex == 0) {
                selectedIndex = 0
            }.font(.system(size: 25))
            Spacer()
            TabItem(image: "calendar", title: "Manage Slots", isSelected: selectedIndex == 1) {
                selectedIndex = 1
            }.font(.system(size: 25))
            Spacer()
            TabItem(image: "person.2", title: "Patients", isSelected: selectedIndex == 2) {
                selectedIndex = 2
            }.font(.system(size: 25))
            Spacer()
        }
        .padding()
        .background(theme.card)
        .frame(height: 40)
    }
}

// Tab item component
struct TabItem: View {
    let image: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: image)
                    .foregroundColor(isSelected ? theme.primary : .gray)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? theme.primary : .gray)
            }
        }
    }
}

#Preview {
    DoctorTabView()
        .environmentObject(DoctorManager())
}
