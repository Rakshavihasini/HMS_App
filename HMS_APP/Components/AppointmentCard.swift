//
//  AppointmentCard.swift
//  HMS_APP
//
//  Created by rjk on 02/05/25.
//
import SwiftUI

struct AppointmentCard: View {
    let appointment: AppointmentData
    
    var statusColor: Color {
        guard let status = appointment.status else {
            return .gray
        }
        
        switch status {
        case .scheduled: return .medicareBlue
        case .completed: return .gray
        case .cancelled: return .medicareRed
        case .inProgress: return .medicareGreen
        case .noShow: return .medicareRed
        case .rescheduled: return .medicareBlue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appointment.doctorName)
                    .font(.headline)
                Spacer()
                if let status = appointment.status {
                    Text(status.rawValue)
                        .font(.caption)
                        .padding(5)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(5)
                }
            }
            
            if let notes = appointment.notes {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Image(systemName: "calendar")
                if let dateTime = appointment.appointmentDateTime {
                    Text(dateTime, style: .date)
                    Text("at")
                    Text(dateTime, style: .time)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
