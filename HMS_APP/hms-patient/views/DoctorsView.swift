//
//  DoctorsView.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//

import SwiftUI
import FirebaseFirestore

struct DoctorsView: View {
    @StateObject private var doctorService = DoctorService()
    @State private var searchText = ""
    @State private var selectedDepartment = "All"
    @State private var selectedAvailability = "All"
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    
    let departments = ["All", "Cardiology", "Neurology", "Orthopedics", "Pediatrics"]
    let availabilityOptions = ["All", "Available Today"]
    
    var filteredDoctors: [Doctor] {
        doctorService.doctors.filter { doctor in
            let matchesDepartment = selectedDepartment == "All" || doctor.speciality == selectedDepartment
            let matchesAvailability = selectedAvailability == "All" 
            // For "Available Today" filter, we'd need to implement availability logic based on schedules
            let matchesSearch = searchText.isEmpty ||
                doctor.name.localizedCaseInsensitiveContains(searchText) ||
                doctor.speciality.localizedCaseInsensitiveContains(searchText)
            
            return matchesDepartment && matchesAvailability && matchesSearch
        }
    }
    
    func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header & Search
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(.medicareBlue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                Text("Find Your Specialist")
                    .font(.title)
                    .bold()
                    .padding(.horizontal)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by name, speciality", text: $searchText)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(30)
                .padding(.horizontal)
            }
            .padding(.top)

            // Filter + Symptoms
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Department
                    Menu {
                        ForEach(departments, id: \.self) { dept in
                            Button(action: {
                                selectedDepartment = dept
                                // We'll handle filtering in the filteredDoctors computed property
                                // instead of fetching by speciality
                            }) {
                                Text(dept)
                            }
                        }
                    } label: {
                        Text(selectedDepartment)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                    
                    // Availability Date Picker (as a button + sheet)
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation {
                                showDatePicker.toggle()
                            }
                        }) {
                            Label(dateFormatted(selectedDate), systemImage: "calendar")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }

                        if showDatePicker {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .transition(.opacity.combined(with: .slide))
                            .padding(8)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 3)
                            .padding(.top, 4)
                        }
                    }
                    .onChange(of: selectedDate) { _ in
                        withAnimation {
                            showDatePicker = false
                        }
                    }

                    
                    // Questionnaire
                    NavigationLink(destination: QuestionaireContentView()) {
                        Label("Find By Symptoms", systemImage: "stethoscope")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.medicareBlue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }

            // Doctor Cards
            if doctorService.doctors.isEmpty {
                Spacer()
                ProgressView("Loading doctors...")
                Spacer()
            } else if filteredDoctors.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No doctors found")
                        .font(.headline)
                    Text("Try adjusting your search criteria")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredDoctors, id: \.id) { doctor in
                            NavigationLink(destination: DoctorDetailView(doctor: convertToProfile(doctor))) {
                                DoctorCard(doctor: doctor)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            doctorService.fetchDoctors()
        }
    }
    
    // Helper function to convert Doctor to DoctorProfile for compatibility with DoctorDetailView
    private func convertToProfile(_ doctor: Doctor) -> DoctorProfile {
        let age: Int? = nil
        if let dob = doctor.dateOfBirth {
            // Calculate age from date of birth if needed
        }
        
        // Create license details
        let licenseDetails = LicenseDetails(
            councilName: doctor.smc,
            registrationNumber: nil,
            verificationStatus: nil,
            verifiedAt: nil,
            yearOfRegistration: doctor.yearOfRegistration
        )
        
        return DoctorProfile(
            id: doctor.id,
            name: doctor.name,
            speciality: doctor.speciality,
            database: nil,
            age: age,
            schedules: nil,
            appwriteUserId: nil,
            gender: doctor.gender,
            licenseDetails: licenseDetails,
            createdAt: nil,
            lastActive: nil
        )
    }
}

// Custom Doctor Card for the Admin Doctor model
struct DoctorCard: View {
    let doctor: Doctor
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.medicareBlue)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                    .font(.headline)
                
                Text(doctor.speciality)
                    .font(.subheadline)
                    .foregroundColor(.medicareBlue)
                
                if let gender = doctor.gender {
                    Text(gender)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(doctor.email)
                        .font(.caption)
                        .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
                .padding(.top, 8)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct DoctorDetailView: View {
    let doctor: DoctorProfile
    @State private var showingBookAppointment = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.medicareBlue)
                    .clipShape(Circle())
                    .shadow(radius: 5)

                Text(doctor.name)
                    .font(.title)
                    .bold()
                
                Text(doctor.speciality)
                    .font(.headline)
                    .foregroundColor(.medicareBlue)

                if let age = doctor.age {
                    HStack(spacing: 10) {
                        Label("Age: \(age)", systemImage: "person")
                        if let gender = doctor.gender {
                            Label(gender, systemImage: "figure.stand")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }

                // License details if available
                if let license = doctor.licenseDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("License Information")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        if let council = license.councilName {
                            Text("Council: \(council)")
                                .font(.subheadline)
                        }
                        
                        if let regNum = license.registrationNumber {
                            Text("Registration #: \(regNum)")
                                .font(.subheadline)
                        }
                        
                        if let year = license.yearOfRegistration {
                            Text("Year of Registration: \(year)")
                                .font(.subheadline)
                        }
                        
                        if let status = license.verificationStatus {
                            Text("Status: \(status)")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                Button("Book Appointment") {
                    showingBookAppointment = true
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.medicareBlue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle(doctor.name)
        .sheet(isPresented: $showingBookAppointment) {
            BookAppointmentView(doctor: doctor)
        }
    }
}

struct DoctorFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedDepartment: String
    @Binding var selectedAvailability: String
    
    let departments: [String]
    let availabilityOptions: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Search by name...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Picker("Department", selection: $selectedDepartment) {
                    ForEach(departments, id: \.self) { dept in
                        Text(dept).tag(dept)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                
                Picker("Availability", selection: $selectedAvailability) {
                    ForEach(availabilityOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

