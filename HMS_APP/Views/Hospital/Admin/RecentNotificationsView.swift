////
////  RecentNotificationsView.swift
////  HMS_Admin
////
////  Created by s1834 on 25/04/25.
////
//
//import SwiftUI
//
//struct RecentNotificationsView: View {
//    @Environment(\.colorScheme) var colorScheme
//    
//    var currentTheme: Theme {
//        colorScheme == .dark ? Theme.dark : Theme.light
//    }
//    
//    let notifications = [
//        NotificationItem(type: .alert, title: "Staff shortage", message: "Cardiology department needs 2 more nurses", time: "12m ago"),
//        NotificationItem(type: .info, title: "System update", message: "Scheduled maintenance at 2:00 AM", time: "1h ago"),
//        NotificationItem(type: .success, title: "Supply order", message: "Medical supplies have been delivered", time: "3h ago")
//    ]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Recent Notifications")
//                .font(.headline)
//                .foregroundColor(currentTheme.text)
//            
//            ForEach(notifications) { notification in
//                HStack(spacing: 12) {
//                    Circle()
//                        .fill(notification.type.color)
//                        .frame(width: 8, height: 8)
//                    
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text(notification.title)
//                            .font(.subheadline.bold())
//                            .foregroundColor(currentTheme.text)
//                        
//                        Text(notification.message)
//                            .font(.caption)
//                            .foregroundColor(currentTheme.text.opacity(0.6))
//                    }
//                    
//                    Spacer()
//                    
//                    Text(notification.time)
//                        .font(.caption2)
//                        .foregroundColor(currentTheme.text.opacity(0.4))
//                }
//                .padding()
//                .background(currentTheme.card)
//                .cornerRadius(12)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(currentTheme.border, lineWidth: 1)
//                )
//            }
//        }
//    }
//}
//
//struct NotificationItem: Identifiable {
//    let id = UUID()
//    let type: NotificationType
//    let title: String
//    let message: String
//    let time: String
//}
//
//enum NotificationType {
//    case info, success, alert
//    
//    var color: Color {
//        switch self {
//        case .info: return .blue
//        case .success: return .green
//        case .alert: return .orange
//        }
//    }
//}
