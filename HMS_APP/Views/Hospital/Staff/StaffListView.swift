import SwiftUI

struct StaffListView: View {
    @Binding var selectedTab: Int
    @StateObject private var staffService = StaffService()
    @StateObject private var doctorService = DoctorService()
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var showAddStaff = false
    @State private var selectedStaff: Staff?
    @State private var shouldRefreshList = false
    
    let filters = ["All", "Doctor", "Nurse", "Pharmacist", "Receptionist", "Counselor", "Lab Technician"]
    
    // Dictionary to map roles to SF Symbols
    private let roleSymbols = [
        "All": "person.3.fill",
        "Doctor": "stethoscope",
        "Nurse": "cross.case.fill",
        "Pharmacist": "pills.fill",
        "Receptionist": "person.text.rectangle.fill",
        "Counselor": "brain.head.profile",
        "Lab Technician": "testtube.2"
    ]
    
    var filteredStaff: [Staff] {
        // Combine doctors and staff into a single array
        let doctorsAsStaff = doctorService.doctors.map { doctor in
            Staff(
                id: doctor.id,
                name: doctor.name,
                email: doctor.email,
                dateOfBirth: doctor.dateOfBirth,
                joinDate: nil,
                educationalQualification: doctor.speciality, // Use doctor's speciality instead of hardcoded MBBS
                certificates: nil,
                staffRole: "Doctor"
            )
        }
        
        let allStaff = staffService.staffMembers + doctorsAsStaff
        
        let filtered = allStaff.filter { staff in
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
                    // Enhanced Header
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Staff")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                
                                Text("Manage your team")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Stats Circle
                            VStack(alignment: .center) {
                                Text("\(filteredStaff.count)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                                Text("Total")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    
                    // Enhanced Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search staff...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    // Enhanced Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(filters, id: \.self) { filter in
                                FilterPill(
                                    title: filter,
                                    icon: roleSymbols[filter] ?? "person.fill",
                                    isSelected: filter == selectedFilter
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    if staffService.staffMembers.isEmpty && doctorService.doctors.isEmpty {
                        // Enhanced Empty State
                        VStack(spacing: 24) {
                            Spacer()
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 60))
                                .foregroundColor(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                                .opacity(0.6)
                            
                            VStack(spacing: 8) {
                                Text("No Staff Members")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                
                                Text("Add staff members to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: { showAddStaff = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Staff")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                            }
                            Spacer()
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredStaff) { staff in
                                    NavigationLink(destination: 
                                        StaffDetailsView(staff: staff, shouldRefreshList: $shouldRefreshList)
                                    ) {
                                        StaffCard(
                                            name: staff.name,
                                            role: staff.staffRole ?? "Staff",
                                            department: staff.educationalQualification ?? "Not specified",
                                            isAvailable: true,
                                            roleIcon: roleSymbols[staff.staffRole ?? ""] ?? "person.fill"
                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                // Enhanced FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddStaff = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
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
                                .shadow(color: (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary).opacity(0.3), radius: 10, x: 0, y: 5)
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
        .onChange(of: shouldRefreshList) { newValue in
            if newValue {
                staffService.fetchStaff()
                doctorService.fetchDoctors()
                shouldRefreshList = false
            }
        }
        .onAppear {
            staffService.fetchStaff()
            doctorService.fetchDoctors()
        }
    }
}

// Enhanced FilterPill
struct FilterPill: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.subheadline)
            }
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

// Enhanced StaffCard
struct StaffCard: View {
    @Environment(\.colorScheme) var colorScheme
    let name: String
    let role: String
    let department: String
    let isAvailable: Bool
    let roleIcon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .dark ? Theme.dark.primary.opacity(0.2) : Theme.light.primary.opacity(0.2),
                            colorScheme == .dark ? Theme.dark.primary.opacity(0.1) : Theme.light.primary.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: roleIcon)
                    .font(.system(size: 20))
                    .foregroundColor(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                HStack {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(role)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "book.closed")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(department)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status indicator with label
            VStack(spacing: 4) {
                Circle()
                    .fill(isAvailable ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(isAvailable ? "Active" : "Away")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Placeholder for AddStaffView
