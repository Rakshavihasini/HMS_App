import SwiftUI

struct HospitalView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            StaffListView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Staff")
                }
                .tag(1)
            
            PatientsListView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Patients")
                }
                .tag(2)
            
            ProfileView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    HospitalView()
} 