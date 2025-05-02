import SwiftUI

struct StaffListView: View {
    @Binding var selectedTab: Int
    @StateObject private var staffService = StaffService()
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var showAddStaff = false
    @State private var selectedStaff: Staff?
    
    let filters = ["All", "Doctor", "Nurse", "Pharmacist", "Receptionist", "Counselor", "Lab Technician"]
    
    var filteredStaff: [Staff] {
        let filtered = staffService.staffMembers.filter { staff in
            if searchText.isEmpty {
                return true
            }
            return staff.name.localizedCaseInsensitiveContains(searchText)
        }
        
        if selectedFilter == "All" {
            return filtered
        }
        
        return filtered.filter { $0.staffRole == selectedFilter }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Theme.dark.background : Theme.light.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Staff")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    
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
                    
                    if staffService.staffMembers.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No Staff Members")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Add staff members to get started")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredStaff) { staff in
                                    NavigationLink(destination: 
                                        GenericStaffDetailsView(staff: staff)
                                    ) {
                                        StaffCard(
                                            name: staff.name,
                                            role: staff.staffRole ?? "Staff",
                                            department: staff.educationalQualification ?? "Not specified",
                                            isAvailable: true
                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddStaff = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            colorScheme == .dark ? Theme.dark.primary : Theme.light.primary,
                                            colorScheme == .dark ? Theme.dark.primary.opacity(0.8) : Theme.light.primary.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showAddStaff) {
                AddStaffView()
            }
        }
        .onAppear {
            staffService.fetchStaff()
        }
    }
}

struct FilterPill: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary) :
                    (colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                )
                .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
        }
    }
}

struct StaffCard: View {
    @Environment(\.colorScheme) var colorScheme
    let name: String
    let role: String
    let department: String
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(colorScheme == .dark ? Theme.dark.primary.opacity(0.2) : Theme.light.primary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(name.prefix(2)))
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
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
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
}

// Placeholder for AddStaffView
