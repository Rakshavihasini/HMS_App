//
//  AdminDashboardView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI
import Charts
import FirebaseFirestore

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
                    
                    // Payment Confirmations Section
                    NavigationLink(destination: AdminAppointmentView()) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Payment Confirmations")
                                    .font(.headline)
                                    .foregroundColor(currentTheme.text)
                                
                                Text("Verify counter payments for appointments")
                                    .font(.subheadline)
                                    .foregroundColor(currentTheme.text.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "creditcard.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(currentTheme.primary)
                        }
                        .padding()
                        .background(currentTheme.card)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    
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
