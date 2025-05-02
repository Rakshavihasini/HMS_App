//
//  AdminDashboardView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts

struct AdminDashboardView: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthManager
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let userName = authManager.currentUser?.name ?? "Admin"
        
        switch hour {
        case 5..<12:
            return "Good Morning,\n\(userName)"
        case 12..<17:
            return "Good Afternoon,\n\(userName)"
        case 17..<22:
            return "Good Evening,\n\(userName)"
        default:
            return "Hello,\n\(userName)"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Greeting
                    HStack {
                        Text(greeting)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(currentTheme.text)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Summary Stats
                    HStack(spacing: 16) {
                        NavigationLink(destination: ConsultationDetailView()) {
                            ConsultationsPerHourCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: RevenueDetailView()) {
                            RevenueCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Charts with Navigation
                    VStack(spacing: 24) {
                        NavigationLink(destination: ConsultationDetailView()) {
                            ConsultationsChartView()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: RevenueDetailView()) {
                            RevenueChartView()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Staff Status Section
                    StaffStatusView()
                        .padding(.horizontal)
                    
                    // Recent Notifications
//                    RecentNotificationsView()
//                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    HStack {
//                        Circle()
//                            .fill(Color.green)
//                            .frame(width: 8, height: 8)
//                        
//                        CurrentTimeView()
//                            .font(.subheadline.bold())
//                    }
//                }
//                
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {}) {
//                        Image(systemName: "bell.badge")
//                            .foregroundColor(currentTheme.primary)
//                    }
//                }
//            }
            .background(currentTheme.background.ignoresSafeArea())
        }
    }
}
