import SwiftUI
import Charts

struct AdminDashboardView: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Stats
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Today's Consultations",
                            value: "24",
                            trend: "+12%",
                            icon: "stethoscope",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Revenue",
                            value: "$2.4K",
                            trend: "+8%",
                            icon: "dollarsign.circle",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Staff Status Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Staff Status")
                            .font(.headline)
                        
                        VStack(spacing: 16) {
                            StaffStatusRow(title: "Doctors On Duty", count: 12, total: 15)
                            StaffStatusRow(title: "Nurses Available", count: 8, total: 10)
                            StaffStatusRow(title: "Staff Present", count: 45, total: 50)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let trend: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(trend)
                    .font(.caption)
                    .foregroundColor(trend.hasPrefix("+") ? .green : .red)
            }
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct StaffStatusRow: View {
    let title: String
    let count: Int
    let total: Int
    
    var percentage: Double {
        Double(count) / Double(total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(count)/\(total)")
                    .font(.subheadline.bold())
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(percentage >= 70 ? Color.green : (percentage >= 40 ? Color.yellow : Color.red))
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
} 