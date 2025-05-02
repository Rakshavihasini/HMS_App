////
////  TabBar.swift
////  HMS_Admin
////
////  Created by rjk on 24/04/25.
////
//import SwiftUI
//
//struct TabBar: View {
//    @Binding var selectedTab: Int
//    
//    var body: some View {
//        HStack(spacing: 0) {
//            TabBarButton(
//                image: "house", // Keep as house
//                title: "Dashboard",
//                isSelected: selectedTab == 0,
//                action: { selectedTab = 0 }
//            )
//            
//            TabBarButton(
//                image: "stethoscope", // Changed from heart to stethoscope
//                title: "Staff",
//                isSelected: selectedTab == 1,
//                action: { selectedTab = 1 }
//            )
//            
//            TabBarButton(
//                image: "person.2", // Keep as person.2
//                title: "Patients",
//                isSelected: selectedTab == 2,
//                action: { selectedTab = 2 }
//            )
//            
//            TabBarButton(
//                image: "person.crop.circle", // Keep as person.crop.circle
//                title: "Profile",
//                isSelected: selectedTab == 3,
//                action: { selectedTab = 3 }
//            )
//        }
//        .padding(.bottom, 16)
//        .padding(.horizontal, 30) // Add horizontal padding
//        .padding(.top, 8) // Add padding above icons/text
//        .frame(height: 80) // Define a fixed height for the tab bar background
//        .background(Color(uiColor: .systemBackground))
//        // Apply corner radius only to top corners
//        .cornerRadius(15, corners: [.topLeft, .topRight])
//        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5) // Slightly adjusted shadow
//    }
//}
//
//struct TabBarButton: View {
//    let image: String
//    let title: String
//    let isSelected: Bool
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 4) {
//                Image(systemName: image)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 22, height: 22)
//                    .foregroundColor(isSelected ? .blue : .gray)
//                
//                Text(title)
//                    .font(.caption) // Slightly larger caption size
//                    .foregroundColor(isSelected ? .blue : .gray)
//            }
//            .frame(maxWidth: .infinity) // Ensure buttons space out evenly
//            .frame(height: 50) // Set a consistent height for the tappable area
//        }
//        .buttonStyle(PlainButtonStyle()) // Use plain button style to avoid default button visuals
//    }
//}
//
//
//extension View {
//    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//        clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//}
//
//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners: UIRectCorner = .allCorners
//    
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(
//            roundedRect: rect,
//            byRoundingCorners: corners,
//            cornerRadii: CGSize(width: radius, height: radius)
//        )
//        return Path(path.cgPath)
//    }
//}
//
