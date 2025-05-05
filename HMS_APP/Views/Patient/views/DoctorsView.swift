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
        VStack(spacing: 0) {
            // Enhanced Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Find Your Specialist")
                            .font(.system(size: 28, weight: .bold))
                        Text("Book appointments with top specialists")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)

                // Enhanced Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by name, speciality", text: $searchText)
                        .foregroundColor(.primary)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemGray6))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                )
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)

            // Enhanced Filters Section
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Department Menu
                    Menu {
                        ForEach(departments, id: \.self) { dept in
                            Button(action: { selectedDepartment = dept }) {
                                HStack {
                                    Text(dept)
                                    if selectedDepartment == dept {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "building.2")
                            Text(selectedDepartment)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.medicareBlue.opacity(0.1))
                        )
                        .foregroundColor(.medicareBlue)
                    }

                    // Date Selection
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation(.spring()) {
                                showDatePicker.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text(dateFormatted(selectedDate))
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.medicareBlue.opacity(0.1))
                            )
                            .foregroundColor(.medicareBlue)
                        }

                        if showDatePicker {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            )
                            .padding(.top, 8)
                        }
                    }

                    // Symptoms Button
                    NavigationLink(destination: QuestionaireContentView()) {
                        HStack {
                            Image(systemName: "stethoscope")
                            Text("Find By Symptoms")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.medicareBlue)
                        )
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)

            // Enhanced Doctor List
            if doctorService.doctors.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading doctors...")
                        .foregroundColor(.gray)
                }
                Spacer()
            } else if filteredDoctors.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No doctors found")
                        .font(.headline)
                    Text("Try adjusting your search criteria")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredDoctors, id: \.id) { doctor in
                            NavigationLink(destination: DoctorDetailView(doctor: convertToProfile(doctor))) {
                                EnhancedDoctorCard(doctor: doctor)
                            }
                        }
                    }
                    .padding()
                }
            }
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

// Enhanced Doctor Card
struct EnhancedDoctorCard: View {
    let doctor: Doctor
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar Section
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.medicareBlue.opacity(0.2), Color.medicareBlue.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.medicareBlue)
            }
            
            // Info Section
            VStack(alignment: .leading, spacing: 6) {
                Text(doctor.name)
                    .font(.system(size: 18, weight: .semibold))
                
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.medicareBlue)
                        .font(.system(size: 12))
                    Text(doctor.speciality)
                        .font(.system(size: 14))
                        .foregroundColor(.medicareBlue)
                }
                
                if let gender = doctor.gender {
                    HStack {
                        Image(systemName: gender.lowercased() == "male" ? "person" : "person.dress")
                            .font(.system(size: 12))
                        Text(gender)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Arrow and Status
            VStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

struct DoctorDetailView: View {
    let doctor: DoctorProfile
    @State private var showingBookAppointment = false
    @State private var currentPatient: Patient?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToHome = false
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else {
                VStack{
                    HStack{
                        Button(action: {
                            navigateToHome = true
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                                .imageScale(.large)
                                .padding(8)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
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
                            fetchPatientAndBook()
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
            }
        }
        .background(
            NavigationLink(
                destination: PatientHomeView(),
                isActive: $navigateToHome
            ) {
                EmptyView()
            }
            .hidden()
        )
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingBookAppointment) {
            if let patient = currentPatient {
                BookAppointmentView(doctor: doctor, patient: patient)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func fetchPatientAndBook() {
        guard let userId = UserDefaults.standard.string(forKey: "userId") else {
            errorMessage = "User not logged in"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let document = try await db.collection("\(dbName)_patients")
                    .document(userId)
                    .getDocument()
                
                if document.exists, let data = document.data() {
                    // Create patient from Firestore data
                    let dateOfBirth: Date? = (data["dob"] as? Timestamp)?.dateValue()
                    
                    let patient = Patient(
                        id: userId,
                        name: data["name"] as? String ?? "",
                        number: data["number"] as? Int,
                        email: data["email"] as? String ?? "",
                        dateOfBirth: dateOfBirth,
                        gender: data["gender"] as? String
                    )
                    
                    await MainActor.run {
                        self.currentPatient = patient
                        self.isLoading = false
                        self.showingBookAppointment = true
                    }
                } else {
                    // If patient document doesn't exist, create one with basic info
                    let patient = Patient(
                        id: userId,
                        name: UserDefaults.standard.string(forKey: "userName") ?? "",
                        email: UserDefaults.standard.string(forKey: "userEmail") ?? "",
                        dateOfBirth: nil,
                        gender: nil
                    )
                    
                    // Save new patient to Firestore
                    try await db.collection("\(dbName)_patients")
                        .document(userId)
                        .setData([
                            "id": patient.id,
                            "name": patient.name,
                            "email": patient.email,
                            "createdAt": FieldValue.serverTimestamp(),
                            "database": dbName
                        ])
                    
                    await MainActor.run {
                        self.currentPatient = patient
                        self.isLoading = false
                        self.showingBookAppointment = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch patient data: \(error.localizedDescription)"
                }
            }
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

