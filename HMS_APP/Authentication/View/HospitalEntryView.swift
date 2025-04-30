//
//  HospitalEntryView.swift
//  HMS_Admin
//
//  Created by rjk on 24/04/25.
//


import SwiftUI

struct HospitalEntryView: View {
    @State private var hospitalName: String = ""
    @State private var navigateToHome = false
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 10) {
                Text("Hospital Details")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Enter your hospital's name to proceed.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            TextField("Hospital Name", text: $hospitalName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.top, 40)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                // Navigate to next screen
                navigateToHome = true
            }) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hospitalName.isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .disabled(hospitalName.isEmpty)
            .padding(.bottom)
        }
        .padding(.top)
        .navigationDestination(isPresented: $navigateToHome) {
//            TabBarContent()
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    HospitalEntryView()
}
