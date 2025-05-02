////
////  PatientDetailView.swift
////  HMS_Admin
////
////  Created by rjk on 24/04/25.
////
//
//import SwiftUI
//
//// Appointment model
//struct Appointment: Identifiable {
//    let id = UUID()
//    let type: String
//    let date: String
//    let time: String
//    let status: String
//    let progress: Float // 0.0 to 1.0
//}
//
//struct PatientDetailView: View {
//    @Environment(\.dismiss) var dismiss
//    @Environment(\.colorScheme) var colorScheme
//    let patient: Patient
//    
//    // Mock financial data
//    let totalBill: String = "2400"
//    let paid: String = "2400"
//    let pending: String = "2400"
//    
//    // Mock appointments data
//    @State private var appointments: [Appointment] = [
//        Appointment(type: "General Checkup", date: "08-09-2023", time: "10:30 AM", status: "Completed", progress: 1.0),
//        Appointment(type: "Dental Cleaning", date: "15-10-2023", time: "02:15 PM", status: "Completed", progress: 1.0),
//        Appointment(type: "Annual Physical", date: "22-11-2023", time: "09:00 AM", status: "Completed", progress: 1.0)
//    ]
//    
//    var body: some View {
//        ZStack(alignment: .top) {
//            // Background color for the entire view
//            (colorScheme == .dark ? Color(UIColor.systemGray6) : Color(.systemGray6))
//                .ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                // Blue header with gradient extending into safe area
//                ZStack(alignment: .bottom) {
//                    // Background gradient for both light and dark modes
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            colorScheme == .dark ? Color(red: 0.15, green: 0.4, blue: 0.8) : Color(red: 0.2, green: 0.5, blue: 0.9),
//                            colorScheme == .dark ? Color(red: 0.24, green: 0.46, blue: 0.78) : Color(red: 0.29, green: 0.56, blue: 0.88)
//                        ]),
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                    .edgesIgnoringSafeArea(.top) // Extend blue into top safe area
//                    
//                    VStack(spacing: 0) {
//                        // Back button and title
//                        HStack {
//                            Button(action: {
//                                dismiss()
//                            }) {
//                                Image(systemName: "chevron.left")
//                                    .foregroundColor(.white)
//                                    .imageScale(.large)
//                                    .padding(8)
//                                    .clipShape(Circle())
//                            }
//                            
//                            Spacer()
//                            
//                            Text("Patient Details")
//                                .font(.system(size: 18, weight: .semibold))
//                                .foregroundColor(.white)
//                            
//                            Spacer()
//                            
//                            Button(action: {
//                                // Action for menu
//                            }) {
//                                Image(systemName: "ellipsis")
//                                    .foregroundColor(.white)
//                                    .imageScale(.large)
//                                    .padding(8)
//                                    .clipShape(Circle())
//                            }
//                        }
//                        .padding(.horizontal)
//                        
//                        // Patient info section
//                        VStack(spacing: 16) {
//                            HStack(alignment: .center, spacing: 16) {
//                                ZStack {
//                                    Circle()
//                                        .fill(Color.white.opacity(0.3))
//                                        .frame(width: 70, height: 70)
//                                    
//                                    Image(systemName: "person.fill")
//                                        .resizable()
//                                        .scaledToFit()
//                                        .foregroundColor(.white)
//                                        .frame(width: 30, height: 30)
//                                }
//                                
//                                VStack(alignment: .leading, spacing: 3) {
//                                    Text(patient.name)
//                                        .font(.system(size: 20, weight: .semibold))
//                                        .foregroundColor(.white)
//                                    
//                                    HStack {
//                                        Image(systemName: "phone.fill")
//                                            .foregroundColor(.white.opacity(0.8))
//                                            .font(.footnote)
//                                        Text(patient.phoneNumber)
//                                            .foregroundColor(.white)
//                                            .font(.system(size: 14))
//                                    }
//                                    .padding(.top, 6)
//                                    
//                                    HStack {
//                                        Image(systemName: "person.fill")
//                                            .foregroundColor(.white.opacity(0.8))
//                                            .font(.footnote)
//                                        Text("33, \(patient.gender)")
//                                            .foregroundColor(.white)
//                                            .font(.system(size: 14))
//                                    }
//                                    .padding(.top, 2)
//                                }
//                                
//                                Spacer()
//                            }
//                            
//                            // Financial summary
//                            HStack(spacing: 0) {
//                                VStack(spacing: 6) {
//                                    Text("₹\(totalBill)")
//                                        .font(.system(size: 20, weight: .bold))
//                                        .foregroundColor(.white)
//                                    Text("Total Bill")
//                                        .font(.system(size: 13))
//                                        .foregroundColor(.white.opacity(0.8))
//                                }                              .frame(maxWidth: .infinity)
//                              .padding(.vertical, 12)
//                              
//                              Divider()
//                                  .background(Color.white.opacity(0.3))
//                                  .frame(height: 34)
//                              
//                              VStack(spacing: 6) {
//                                  Text("₹\(paid)")
//                                      .font(.system(size: 20, weight: .bold))
//                                      .foregroundColor(.white)
//                                  Text("Paid")
//                                      .font(.system(size: 13))
//                                      .foregroundColor(.white.opacity(0.8))
//                              }
//                              .frame(maxWidth: .infinity)
//                              .padding(.vertical, 12)
//                              
//                              Divider()
//                                  .background(Color.white.opacity(0.3))
//                                  .frame(height: 34)
//                              
//                              VStack(spacing: 6) {
//                                  Text("₹\(pending)")
//                                      .font(.system(size: 20, weight: .bold))
//                                      .foregroundColor(.white)
//                                  Text("Pending")
//                                      .font(.system(size: 13))
//                                      .foregroundColor(.white.opacity(0.8))
//                              }
//                              .frame(maxWidth: .infinity)
//                              .padding(.vertical, 12)
//                          }
//                          .background(
//                              Color.white.opacity(0.05)
//                                  .blur(radius: 10)
//                          )
//                          .cornerRadius(14)
//                          .overlay(
//                              RoundedRectangle(cornerRadius: 14)
//                                  .stroke(Color.white.opacity(0.2), lineWidth: 1)
//                          )
//                          .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
//                      }
//                      .padding(.horizontal)
//                      .padding(.top, 10)
//                      .padding(.bottom, 18)
//                  }
//              }
//              .frame(height: 200)
//                                          
//                                        
//                // Appointments header
//                HStack {
//                    Text("Appointments")
//                        .font(.system(size: 20, weight: .bold))
//                        .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.3, blue: 0.6))
//                    
//                    Spacer()
//                    
//                    Button(action: {
//                        // Calendar action
//                    }) {
//                        HStack(spacing: 8) {
//                            Image(systemName: "plus")
//                                .font(.system(size: 14, weight: .bold))
//                            
//                            Text("New")
//                                .font(.system(size: 14, weight: .semibold))
//                        }
//                        .foregroundColor(.white)
//                        .padding(.vertical, 8)
//                        .padding(.horizontal, 16)
//                        .background(
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.blue, Color(red: 0.2, green: 0.5, blue: 0.9)]),
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            )
//                        )
//                        .cornerRadius(20)
//                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
//                    }
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 20)
//                .padding(.bottom, 16)
//                
//                // Content area
//                ScrollView {
//                    VStack(spacing: 16) {
//                        ForEach(appointments) { appointment in
//                            FinalAppointmentCard(appointment: appointment, colorScheme: colorScheme)
//                                .padding(.horizontal, 20)
//                        }
//                    }
//                    .padding(.vertical, 12)
//                    .padding(.bottom, 20)
//                }
//                .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
//            }
//            .safeAreaInset(edge: .top) {
//                Color.clear.frame(height: 0)
//            }
//        }
//        .navigationBarHidden(true)
//    }
//}
//
//// Appointment card view
//struct FinalAppointmentCard: View {
//    let appointment: Appointment
//    let colorScheme: ColorScheme
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            ZStack {
//                Circle()
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [
//                                colorScheme == .dark ? Color(UIColor.systemGray4) : Color(red: 0.9, green: 0.95, blue: 1.0),
//                                colorScheme == .dark ? Color(UIColor.systemGray5) : Color(red: 0.85, green: 0.9, blue: 0.98)
//                            ]),
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 56, height: 56)
//                
//                Image(systemName: getIconName(for: appointment.type))
//                    .resizable()
//                    .scaledToFit()
//                    .foregroundColor(.blue)
//                    .frame(width: 24, height: 24)
//            }
//            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
//            
//            VStack(alignment: .leading, spacing: 6) {
//                Text(appointment.type)
//                    .font(.system(size: 17, weight: .semibold))
//                    .foregroundColor(colorScheme == .dark ? .white : .primary)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    HStack(spacing: 6) {
//                        Image(systemName: "calendar")
//                            .font(.system(size: 12))
//                            .foregroundColor(colorScheme == .dark ? .gray : Color(.systemGray))
//                        
//                        Text(appointment.date)
//                            .font(.system(size: 14))
//                            .foregroundColor(colorScheme == .dark ? .gray : Color(.systemGray))
//                    }
//                    
//                    HStack(spacing: 6) {
//                        Image(systemName: "clock")
//                            .font(.system(size: 12))
//                            .foregroundColor(colorScheme == .dark ? .gray : Color(.systemGray))
//                        
//                        Text(appointment.time)
//                            .font(.system(size: 14))
//                            .foregroundColor(colorScheme == .dark ? .gray : Color(.systemGray))
//                    }
//                }
//            }
//            
//            Spacer()
//            
//            HStack(spacing: 6) {
//                Circle()
//                    .fill(statusColor(for: appointment.status))
//                    .frame(width: 8, height: 8)
//                
//                Text(appointment.status)
//                    .font(.system(size: 13, weight: .semibold))
//                    .foregroundColor(statusColor(for: appointment.status))
//            }
//            .padding(.vertical, 6)
//            .padding(.horizontal, 12)
//            .background(
//                Capsule()
//                    .fill(statusColor(for: appointment.status).opacity(0.15))
//            )
//        }
//        .padding(.vertical, 16)
//        .padding(.horizontal, 16)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(colorScheme == .dark ? Color(UIColor.systemGray5) : Color.white)
//                .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
//        )
//    }
//    
//    func getIconName(for appointmentType: String) -> String {
//        switch appointmentType.lowercased() {
//        case let type where type.contains("dental"):
//            return "tooth"
//        case let type where type.contains("physical"):
//            return "heart.text.square"
//        case let type where type.contains("checkup"):
//            return "stethoscope"
//        default:
//            return "cross.case"
//        }
//    }
//    
//    func statusColor(for status: String) -> Color {
//        switch status.lowercased() {
//        case "completed":
//            return Color.green
//        case "scheduled":
//            return Color.blue
//        case "cancelled":
//            return Color.red
//        default:
//            return Color.gray
//        }
//    }
//}
//
//// Preview provider
//struct PatientDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            PatientDetailView(patient: Patient(name: "Panda", phoneNumber: "918498493878", gender: "male"))
//                .environment(\.colorScheme, .light)
//            PatientDetailView(patient: Patient(name: "Panda", phoneNumber: "918498493878", gender: "male"))
//                .environment(\.colorScheme, .dark)
//        }
//    }
//}
