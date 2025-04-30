import SwiftUI

struct PatientsListView: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    let filters = ["All", "Admitted", "Outpatient", "Emergency"]
    
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
                
                // Patients List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(0..<10) { index in
                            PatientCard(
                                name: "Patient \(index + 1)",
                                id: String(format: "P%04d", index + 1),
                                status: index % 3 == 0 ? "Admitted" : (index % 3 == 1 ? "Outpatient" : "Emergency"),
                                department: ["Cardiology", "Neurology", "Pediatrics", "Orthopedics"][index % 4]
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Patients")
            .searchable(text: $searchText, prompt: "Search patients...")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct PatientCard: View {
    let name: String
    let id: String
    let status: String
    let department: String
    
    var statusColor: Color {
        switch status {
        case "Admitted":
            return .blue
        case "Outpatient":
            return .green
        case "Emergency":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(statusColor.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(name.prefix(2)))
                        .font(.headline)
                        .foregroundColor(statusColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text(id)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(status)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                    
                    Text(department)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
