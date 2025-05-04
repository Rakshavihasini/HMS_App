//
//  ConsultationCard.swift
//  HMS_APP
//
//  Created by Rudra Pruthi on 02/05/25.
//

import SwiftUI

struct ConsultationCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let appointment: AppointmentData
    let onReschedule: () -> Void
    var onStartConsult: (() -> Void)? = nil
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (Time and Status Badge)
            HStack {
                Text(appointment.date ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.primary)
                
                Spacer()
                
                // Status Badge
                StatusBadge(status: appointment.status?.rawValue ?? "")
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Patient Details
            HStack(spacing: 12) {
                // Avatar Circle
                PatientAvatar(name: appointment.patientName)
                
                // Patient Info
                VStack(alignment: .leading, spacing: 4) {
                    if !appointment.patientName.isEmpty {
                        Text(appointment.patientName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.primary)
                    } else {
                        Text("Patient ID: \(appointment.patientId)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                    
                    Text(appointment.reason ?? "General Checkup")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Buttons
            HStack(spacing: 10) {
                // Reschedule Button
                ActionButton(
                    icon: "calendar.badge.clock",
                    title: "Reschedule",
                    action: onReschedule
                )
                
                // Join Button (only for upcoming appointments)
                if isUpcoming {
                    ActionButton(
                        icon: "play.fill",
                        title: "Start Consult",
                        filled: true,
                        action: {
                            onStartConsult?()
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(theme.card)
        .cornerRadius(16)
        .shadow(color: theme.shadow, radius: 1, x: 0, y: 1)
    }
    
    // Check if appointment is upcoming
    private var isUpcoming: Bool {
        let lowerStatus = appointment.status
        return lowerStatus?.rawValue == "UPCOMING" || lowerStatus?.rawValue == "CONFIRMED" || lowerStatus?.rawValue == "SCHEDULED"
    }
}

// MARK: - Supporting Views

struct PatientAvatar: View {
    let name: String
    
    private var initial: String {
        String(name.first ?? "P")
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
            
            Text(initial)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.blue)
        }
        .frame(width: 40, height: 40)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "upcoming", "confirmed", "scheduled":
            return .green
        case "cancelled":
            return .red
        case "completed":
            return .blue
        default:
            return .gray
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    var filled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(filled ? .white : .blue)
            .background(
                filled ? 
                Color.blue :
                Color.blue.opacity(0.1)
            )
            .cornerRadius(8)
        }
    }
} 
