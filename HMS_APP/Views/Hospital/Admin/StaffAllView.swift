//
//  StaffAllView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import FirebaseFirestore

struct StaffAllView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var staffService = StaffService()
    @StateObject private var doctorService = DoctorService()
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    @State private var showingActionSheet = false
    @State private var selectedStaff: Staff?
    
    var allStaffMembers: [Staff] {
        // Convert doctors to staff format and combine with staff
        let doctorsAsStaff = doctorService.doctors.map { doctor in
            Staff(
                id: doctor.id,
                name: doctor.name,
                email: doctor.email,
                dateOfBirth: doctor.dateOfBirth,
                joinDate: nil,
                educationalQualification: doctor.speciality,
                certificates: nil,
                staffRole: "Doctor"
            )
        }
        
        return staffService.staffMembers + doctorsAsStaff
    }
    
    var body: some View {
        VStack {
            if allStaffMembers.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No Staff Members")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Add staff members to get started")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(allStaffMembers) { staff in
                            StaffDetailCard(
                                staff: staff,
                                onMoreOptions: {
                                    selectedStaff = staff
                                    showingActionSheet = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("All Staff")
        .onAppear {
            staffService.fetchStaff()
            doctorService.fetchDoctors()
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(selectedStaff?.name ?? "Staff Actions"),
                message: Text("Choose an action"),
                buttons: [
                    .default(Text("View Profile")) {
                        // Handle view profile action
                    },
                    .default(Text("Schedule Appointment")) {
                        // Handle schedule action
                    },
                    .default(Text("View Schedule")) {
                        // Handle view schedule action
                    },
                    .destructive(Text("Report Issue")) {
                        // Handle report issue action
                    },
                    .cancel()
                ]
            )
        }
        .background(currentTheme.background)
    }
}

struct StaffDetailCard: View {
    let staff: Staff
    let onMoreOptions: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(staff.status?.color ?? .green)
                    .frame(width: 12, height: 12)
                
                Text(staff.status?.rawValue ?? "Available")
                    .font(.caption)
                    .foregroundColor(currentTheme.text.opacity(0.6))
                
                Spacer()
            }
            
            Text(staff.name)
                .font(.headline)
                .foregroundColor(currentTheme.text)
            
            Text(staff.staffRole ?? "Staff")
                .font(.caption)
                .foregroundColor(currentTheme.text.opacity(0.6))
        }
        .padding()
        .background(currentTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTheme.border, lineWidth: 1)
        )
        .shadow(color: currentTheme.shadow, radius: 5, x: 0, y: 2)
    }
}
