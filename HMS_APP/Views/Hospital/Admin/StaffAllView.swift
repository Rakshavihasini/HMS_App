//
//  StaffAllView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI

struct StaffAllView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    @State private var staffMembers = [
        StaffMember(name: "Dr. Johnson", specialty: "Cardiology", status: .available),
        StaffMember(name: "Dr. Williams", specialty: "Neurology", status: .busy),
        StaffMember(name: "Dr. Lee", specialty: "Pediatrics", status: .breaks),
        StaffMember(name: "Dr. Garcia", specialty: "General", status: .offDuty),
        StaffMember(name: "Dr. Singh", specialty: "Orthopedics", status: .available),
        StaffMember(name: "Dr. Martinez", specialty: "Dermatology", status: .busy),
        StaffMember(name: "Dr. Chen", specialty: "Ophthalmology", status: .breaks),
        StaffMember(name: "Dr. Wilson", specialty: "Pulmonology", status: .available),
        StaffMember(name: "Dr. Brown", specialty: "Gynecology", status: .offDuty),
        StaffMember(name: "Dr. Taylor", specialty: "Psychiatry", status: .busy)
    ]
    
    @State private var showingMessageSheet = false
    @State private var showingActionSheet = false
    @State private var selectedStaff: StaffMember?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(staffMembers) { staff in
                    StaffDetailCard(
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
            .padding()
        }
        .navigationTitle("All Staff")
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
        .background(currentTheme.background)
    }
}

struct StaffDetailCard: View {
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
                
                Spacer()
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
        .background(currentTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTheme.border, lineWidth: 1)
        )
        .shadow(color: currentTheme.shadow, radius: 5, x: 0, y: 2)
    }
}

struct MessageView: View {
    let recipient: StaffMember
    @State private var messageText = ""
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("To: ")
                        .foregroundColor(currentTheme.text.opacity(0.6))
                    Text(recipient.name)
                        .bold()
                        .foregroundColor(currentTheme.text)
                    Spacer()
                }
                .padding()
                
                Divider()
                
                TextEditor(text: $messageText)
                    .padding()
                    .background(currentTheme.secondary.opacity(0.3))
                    .cornerRadius(8)
                    .padding()
                    .foregroundColor(currentTheme.text)
                
                Button(action: {
                    // Here you'd integrate with your message sending functionality
                    // For now, we'll just dismiss the sheet
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Send Message")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(currentTheme.primary)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(currentTheme.primary)
                }
            }
            .background(currentTheme.background)
        }
    }
}
