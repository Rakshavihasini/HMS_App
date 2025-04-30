import SwiftUI

struct StaffListView: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    let filters = ["All", "Doctors", "Nurses", "Admin"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterPill(title: filter, isSelected: filter == selectedFilter) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Staff List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<10) { index in
                            StaffCard(
                                name: "Dr. John Doe \(index + 1)",
                                role: index % 2 == 0 ? "Doctor" : "Nurse",
                                department: "Cardiology",
                                isAvailable: index % 3 == 0
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Staff")
            .searchable(text: $searchText, prompt: "Search staff...")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(radius: 2)
        }
    }
}

struct StaffCard: View {
    let name: String
    let role: String
    let department: String
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(name.prefix(2)))
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(department)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(isAvailable ? Color.green : Color.red)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
