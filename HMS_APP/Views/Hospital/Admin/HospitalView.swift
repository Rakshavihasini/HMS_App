import SwiftUI

struct HospitalView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Area
            ZStack {
                if selectedTab == 0 {
                    AdminDashboardView(selectedTab: $selectedTab)
                } else if selectedTab == 1 {
                    StaffListView(selectedTab: $selectedTab)
                } else if selectedTab == 2 {
                    PatientsListView(selectedTab: $selectedTab)
                } else if selectedTab == 3 {
                    ProfileView(selectedTab: $selectedTab)
                }
            }
            
            // Custom Tab Bar
            HospitalTabBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden()
    }
}

struct HospitalTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            TabBarButton(title: "Dashboard", icon: "square.grid.2x2", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabBarButton(title: "Staff", icon: "person.2", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabBarButton(title: "Patients", icon: "heart.text.square", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            
            TabBarButton(title: "Profile", icon: "person.circle", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: -5)
    }
}

struct TabBarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
        }
    }
} 
