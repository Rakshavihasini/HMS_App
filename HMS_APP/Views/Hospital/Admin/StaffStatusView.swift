//
//  StaffStatusView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI

struct StaffStatusView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    let staffStatusData = [
        StaffMember(name: "Dr. Johnson", specialty: "Cardiology", status: .available),
        StaffMember(name: "Dr. Williams", specialty: "Neurology", status: .busy),
        StaffMember(name: "Dr. Lee", specialty: "Pediatrics", status: .breaks),
        StaffMember(name: "Dr. Garcia", specialty: "General", status: .offDuty)
    ]
    
    @State private var showingMessageSheet = false
    @State private var showingActionSheet = false
    @State private var selectedStaff: StaffMember?
    
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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(staffStatusData) { staff in
                        StaffStatusCard(
                            staff: staff,
                            onMessage: {
                                selectedStaff = staff
                                showingMessageSheet = true
                            },
                            onMoreOptions: {
                                selectedStaff = staff
                                showingActionSheet = true
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            if let staff = selectedStaff {
                MessageView(recipient: staff)
            }
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
    let staff: StaffMember
    let onMessage: () -> Void
    let onMoreOptions: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(staff.status.color)
                    .frame(width: 12, height: 12)
                
                Text(staff.status.rawValue)
                    .font(.caption)
                    .foregroundColor(currentTheme.text.opacity(0.6))
            }
            
            Text(staff.name)
                .font(.headline)
                .foregroundColor(currentTheme.text)
            
            Text(staff.specialty)
                .font(.caption)
                .foregroundColor(currentTheme.text.opacity(0.6))
            
            HStack {
                Button(action: onMessage) {
                    Label("Message", systemImage: "message.fill")
                        .font(.caption)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(currentTheme.primary.opacity(0.1))
                        .foregroundColor(currentTheme.primary)
                        .cornerRadius(8)
                }
                
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

struct StaffMember: Identifiable {
    let id = UUID()
    let name: String
    let specialty: String
    let status: StaffStatus
}

enum StaffStatus: String {
    case available = "Available"
    case busy = "Busy"
    case breaks = "On Break"
    case offDuty = "Off Duty"
    
    var color: Color {
        switch self {
        case .available: return .green
        case .busy: return .orange
        case .breaks: return .blue
        case .offDuty: return .gray
        }
    }
}
