//
//  StaffStatusView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI

struct StaffStatusView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var staffService = StaffService()
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    @State private var showingActionSheet = false
    @State private var selectedStaff: Staff?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Staff Status")
                    .font(.headline)
                    .foregroundColor(currentTheme.text)
                
                Spacer()
                
                NavigationLink(destination: StaffAllView()) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.primary)
                }
            }
            
            if staffService.staffMembers.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No Staff Members")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(staffService.staffMembers) { staff in
                            StaffStatusCard(
                                staff: staff,
                                onMoreOptions: {
                                    selectedStaff = staff
                                    showingActionSheet = true
                                }
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            staffService.fetchStaff()
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
    }
}

struct StaffStatusCard: View {
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
            }
            
            Text(staff.name)
                .font(.headline)
                .foregroundColor(currentTheme.text)
            
            Text(staff.staffRole ?? "Staff")
                .font(.caption)
                .foregroundColor(currentTheme.text.opacity(0.6))
            
            HStack {
                Spacer()
                
                Button(action: onMoreOptions) {
                    Image(systemName: "ellipsis")
                        .padding(8)
                        .background(currentTheme.secondary)
                        .foregroundColor(currentTheme.text)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .frame(width: 160)
        .background(currentTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTheme.border, lineWidth: 1)
        )
    }
}
