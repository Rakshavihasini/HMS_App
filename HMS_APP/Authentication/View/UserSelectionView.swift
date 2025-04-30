//
//  UserSelectionView.swift
//  Giggle_swiftui
//
//  Created by rjk on 30/04/25.
//


import SwiftUI

struct UserSelectionView: View {
    @State private var selectedUserType: String? = nil
    
    var body: some View {
        ZStack {
            Color(.systemBackground) // Background color
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title
                Text("Select Your User Type")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.top, 40)
                
                // Cards
                CardView(title: "Hospital", destination: HospitalView(), color: Color.blue) { selectedUserType = "hospital" }
                CardView(title: "Doctor", destination: DoctorView(), color: Color.green) { selectedUserType = "doctor" }
                CardView(title: "Patient", destination: PatientView(), color: Color.red) { selectedUserType = "patient" }
                
                Spacer() // Pushes content to the top
            }
            .navigationTitle("") // Optional: Clears default navigation title if used in a navigation stack
        }
    }
}

// Reusable Card View
struct CardView<Destination: View>: View {
    let title: String
    let destination: Destination
    let color: Color
    let action: () -> Void
    
    var body: some View {
        NavigationLink(
            destination: LoginScreen(),
            isActive: Binding(
                get: { selectedUserType == derivedUserType },
                set: { if !$0 { selectedUserType = nil } }
            ),
            label: {
                Button(action: action) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(color)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }
            }
        )
    }
    
    // Computed property to derive user type from title
    private var derivedUserType: String {
        title.lowercased()
    }
    
    @State private var selectedUserType: String? = nil
}

// Placeholder Destination Views
struct HospitalView: View {
    var body: some View {
        Text("Hospital Dashboard")
            .font(.title)
            .navigationTitle("Hospital")
    }
}

struct DoctorView: View {
    var body: some View {
        Text("Doctor Dashboard")
            .font(.title)
            .navigationTitle("Doctor")
    }
}

struct PatientView: View {
    var body: some View {
        Text("Patient Dashboard")
            .font(.title)
            .navigationTitle("Patient")
    }
}

// Preview
#Preview {
    NavigationView {
        UserSelectionView()
    }
}
