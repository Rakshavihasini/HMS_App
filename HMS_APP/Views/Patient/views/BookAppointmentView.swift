import SwiftUI
import FirebaseFirestore


struct BookAppointmentView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    let doctor: DoctorProfile
    let patient: Patient
    @State private var selectedDate = Date()
    @State private var reason = ""
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showAllMorningSlots = false
    @State private var showAllAfternoonSlots = false
    @State private var shouldNavigateBack = false
    @State private var showingPaymentSheet = false
    @State private var appointmentListener: ListenerRegistration?
    
    // Add consultationFee calculation based on doctor's speciality
    private var consultationFee: Int {
        let normalizedSpeciality = doctor.speciality.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("DEBUG: Normalized specialty: '\(normalizedSpeciality)'")
        switch normalizedSpeciality {
        case "cardiologist":
            return 1500
        case "neurologist":
            return 1800
        case "orthopedic":
            return 1200
        case "dermatologist":
            return 800
        case "general physician":
            return 900
        default:
            print("DEBUG: No specialty match found, using default fee")
            return 1000
        }
    }
    
    // Default appointment duration in minutes
    private let appointmentDuration = 30
    
    // Add dateFormatter property
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // Default time slots that will be filtered based on doctor availability
    let defaultTimeSlots = [
        "9:00 AM", "9:30 AM",
        "10:00 AM", "10:30 AM",
        "11:00 AM", "11:30 AM",
        "12:00 PM", "12:30 PM",
        "1:00 PM", "1:30 PM",
        "2:00 PM", "2:30 PM",
        "3:00 PM", "3:30 PM",
        "4:00 PM", "4:30 PM"
    ]
    
    @State private var availableTimeSlots: [String] = []
    @State private var selectedTime = ""
    
    private let db = Firestore.firestore()
    private let dbName = "hms4"
    private let calendar = Calendar.current
    
    // Theme colors
    private var themeBlue: Color {
        colorScheme == .dark ? Color(red: 0.4, green: 0.7, blue: 1.0) : Color(red: 0.129, green: 0.588, blue: 0.953)
    }
    private var themePurple: Color {
        colorScheme == .dark ? Color(red: 0.5, green: 0.3, blue: 0.9) : Color(red: 0.4, green: 0.2, blue: 0.8)
    }
    
    var morningSlots: [String] {
        availableTimeSlots.filter { slot in
            let hour = Int(slot.split(separator: ":")[0]) ?? 0
            return hour >= 9 && hour < 12
        }
    }
    
    var afternoonSlots: [String] {
        availableTimeSlots.filter { slot in
            let hour = Int(slot.split(separator: ":")[0]) ?? 0
            let isPM = slot.contains("PM")
            return (hour == 12 && isPM) || (hour >= 1 && hour <= 5 && isPM)
        }
    }
    
    // Calculate years of experience
    private var yearsOfExperience: Int? {
        // Debug prints to diagnose the issue
        print("DEBUG: Doctor name: \(doctor.name)")
        print("DEBUG: licenseDetails: \(String(describing: doctor.licenseDetails))")
        if let licenseDetails = doctor.licenseDetails {
            print("DEBUG: yearOfRegistration: \(String(describing: licenseDetails.yearOfRegistration))")
            if let year = licenseDetails.yearOfRegistration {
                let currentYear = Calendar.current.component(.year, from: Date())
                return max(0, currentYear - year)
            }
        }
        
        // Return nil if no year of registration is available
        return nil
    }
    
    private var experienceText: String {
        if let years = yearsOfExperience {
            return "\(years) YEARS"
        } else {
            return "EXPERIENCED"  // Fallback text when no year data available
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Doctor Info Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(doctor.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            
                            Text("\(doctor.speciality)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("₹\(consultationFee)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .cornerRadius(12)
                .padding()
                
                // Date Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("SELECT DATE")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<15) { day in
                                if let date = calendar.date(byAdding: .day, value: day, to: Date()) {
                                    let isFullDayLeave = isDateInFullDayLeaves(date)
                                    Button(action: {
                                        if !isFullDayLeave {
                                            selectedDate = date
                            fetchAvailableTimeSlots()
                                        }
                                    }) {
                                        VStack(spacing: 8) {
                                            Text(dayName(for: date))
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("\(dayNumber(for: date))")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                            Text(monthName(for: date))
                                                .font(.caption)
                                                .textCase(.uppercase)
                                        }
                                        .frame(width: 70, height: 90)
                                        .foregroundColor(isFullDayLeave ? .gray : (calendar.isDate(date, inSameDayAs: selectedDate) ? .white : (colorScheme == .dark ? .white : .primary)))
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(isFullDayLeave ? Color.gray.opacity(0.2) : (calendar.isDate(date, inSameDayAs: selectedDate) ? themeBlue : (colorScheme == .dark ? Color(.systemGray5) : Color.white)))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: calendar.isDate(date, inSameDayAs: selectedDate) ? 0 : 1)
                                        )
                                    }
                                    .disabled(isFullDayLeave)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                
                // Time Slots
                VStack(alignment: .leading, spacing: 20) {
                    if isLoading {
                            ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    } else if availableTimeSlots.isEmpty {
                        Text("No available slots for this date")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        // Morning Slots
                        let filteredMorningSlots = morningSlots
                        if !filteredMorningSlots.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(.orange)
                                    Text("Morning")
                                        .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    Spacer()
                                    Button(action: { showAllMorningSlots.toggle() }) {
                                        Text(showAllMorningSlots ? "Show Less" : "View All")
                                            .font(.caption)
                                            .foregroundColor(themeBlue)
                                    }
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(showAllMorningSlots ? filteredMorningSlots : Array(filteredMorningSlots.prefix(4)), id: \.self) { slot in
                                        let isSlotUnavailable = isTimeSlotUnavailable(slot)
                                        Button(action: {
                                            if !isSlotUnavailable {
                                                selectedTime = slot
                                            }
                                        }) {
                                            Text(slot)
                                                .font(.subheadline)
                                                .padding(.vertical, 12)
                                                .frame(maxWidth: .infinity)
                                                .background(isSlotUnavailable ? Color.gray.opacity(0.2) : (selectedTime == slot ? themeBlue : (colorScheme == .dark ? Color(.systemGray5) : Color.white)))
                                                .foregroundColor(isSlotUnavailable ? .gray : (selectedTime == slot ? .white : (colorScheme == .dark ? .white : .primary)))
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: selectedTime == slot ? 0 : 1)
                                                )
                                        }
                                        .disabled(isSlotUnavailable)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Afternoon Slots
                        let filteredAfternoonSlots = afternoonSlots
                        if !filteredAfternoonSlots.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(.orange)
                                    Text("Afternoon")
                                        .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                                    Spacer()
                                    Button(action: { showAllAfternoonSlots.toggle() }) {
                                        Text(showAllAfternoonSlots ? "Show Less" : "View All")
                                            .font(.caption)
                                            .foregroundColor(themeBlue)
                                    }
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(showAllAfternoonSlots ? filteredAfternoonSlots : Array(filteredAfternoonSlots.prefix(4)), id: \.self) { slot in
                                        let isSlotUnavailable = isTimeSlotUnavailable(slot)
                                        Button(action: {
                                            if !isSlotUnavailable {
                                                selectedTime = slot
                                            }
                                        }) {
                                            Text(slot)
                                                .font(.subheadline)
                                                .padding(.vertical, 12)
                                                .frame(maxWidth: .infinity)
                                                .background(isSlotUnavailable ? Color.gray.opacity(0.2) : (selectedTime == slot ? themeBlue : (colorScheme == .dark ? Color(.systemGray5) : Color.white)))
                                                .foregroundColor(isSlotUnavailable ? .gray : (selectedTime == slot ? .white : (colorScheme == .dark ? .white : .primary)))
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: selectedTime == slot ? 0 : 1)
                                                )
                                        }
                                        .disabled(isSlotUnavailable)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Reason for visit
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reason for Visit")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            TextField("Enter your reason for visit", text: $reason)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
                .padding(.vertical)
            }
        }
            .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Select Time Slot")
        .navigationBarBackButtonHidden(false)
        .background(colorScheme == .dark ? Color.black : Color(.systemGray6))
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    // Show payment sheet instead of directly booking appointment
                    showingPaymentSheet = true
                }) {
                    Text("Continue Booking")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedTime.isEmpty ? Color.gray : themeBlue
                        )
                        .cornerRadius(12)
                }
                .disabled(selectedTime.isEmpty)
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            }
        }
        .background(
            NavigationLink(destination: PatientHomeView(), isActive: $shouldNavigateBack) {
                EmptyView()
            }
        )
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentConfirmationView(
                doctor: doctor,
                date: selectedDate,
                time: selectedTime,
                reason: reason,
                consultationFee: consultationFee,
                onConfirm: {
                    showingPaymentSheet = false
                    bookAppointment()
                },
                onCancel: {
                    showingPaymentSheet = false
                }
            )
        }
            .alert(isPresented: $showingConfirmation) {
            // Check payment method to show appropriate confirmation message
            let paymentMethod = UserDefaults.standard.string(forKey: "selectedPaymentMethod") ?? ""
            
            if paymentMethod == "counter" {
                return Alert(
                    title: Text("Appointment Pending"),
                    message: Text("Your appointment with \(doctor.name) on \(formattedDate()) at \(selectedTime) will be confirmed after payment verification at the hospital counter."),
                    dismissButton: .default(Text("OK")) {
                        shouldNavigateBack = true
                    }
                )
            } else {
                return Alert(
                    title: Text("Appointment Booked"),
                    message: Text("Your appointment with \(doctor.name) on \(formattedDate()) at \(selectedTime) has been confirmed."),
                    dismissButton: .default(Text("OK")) {
                        shouldNavigateBack = true
                    }
                )
            }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
            prefetchFullDayLeavesData()
                fetchAvailableTimeSlots()
        }
        .onDisappear {
            // Clean up listener to prevent memory leaks
            appointmentListener?.remove()
        }
    }
    
    private func prefetchFullDayLeavesData() {
        guard let doctorId = doctor.id else { return }
        
        Task {
            do {
                print("DEBUG: Prefetching full day leaves data for doctor \(doctorId)")
                let db = Firestore.firestore()
                let docRef = db.collection("hms4_doctors").document(doctorId)
                let document = try await docRef.getDocument()
                
                if document.exists, let data = document.data(),
                   let scheduleData = data["schedule"] as? [String: Any],
                   let fullDayLeaves = scheduleData["fullDayLeaves"] as? [Any] {
                    
                    var leaveTimestamps: [Double] = []
                    
                    for leave in fullDayLeaves {
                        if let timestamp = leave as? Timestamp {
                            let leaveDate = timestamp.dateValue()
                            leaveTimestamps.append(leaveDate.timeIntervalSince1970)
                            print("DEBUG: Found full day leave timestamp at: \(leaveDate)")
                        }
                    }
                    
                    // Cache all the leave timestamps for future quick checks
                    UserDefaults.standard.set(leaveTimestamps, forKey: "fullDayLeaves_\(doctorId)")
                    
                    // Force UI refresh if needed
                    await MainActor.run {
                        // This will trigger a UI refresh
                        let currentDate = selectedDate
                        selectedDate = currentDate
                    }
                }
            } catch {
                print("DEBUG: Error prefetching full day leaves: \(error)")
            }
        }
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    private func monthName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    private func removeBookedSlot(_ bookedTime: String) {
        print("DEBUG: Removing booked slot: \(bookedTime)")
        availableTimeSlots.removeAll { timeSlot in
            // Direct exact match
            if timeSlot == bookedTime {
                return true
            }
            
            // Try normalized time comparison (handle format differences)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            
            if let slotTime = timeFormatter.date(from: timeSlot),
               let bookTime = timeFormatter.date(from: bookedTime) {
                let calendar = Calendar.current
                
                // Compare hour and minute components
                let slotComponents = calendar.dateComponents([.hour, .minute], from: slotTime)
                let bookComponents = calendar.dateComponents([.hour, .minute], from: bookTime)
                
                return slotComponents.hour == bookComponents.hour && 
                       slotComponents.minute == bookComponents.minute
            }
            
            return false
        }
    }
    
    private func fetchAvailableTimeSlots() {
        isLoading = true
        
        // Clean up any existing listener
        appointmentListener?.remove()
        
        // Format the selected date to match Firebase date format (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: selectedDate)
        
        print("DEBUG: Fetching slots for date: \(dateString)")
        
        // Reset available time slots and view all states
        availableTimeSlots = defaultTimeSlots
        showAllMorningSlots = false
        showAllAfternoonSlots = false
        
        // Only filter out past time slots if the selected date is today
        if calendar.isDateInToday(selectedDate) {
            print("DEBUG: Selected date is today, filtering past time slots")
            let currentTime = Date()
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            timeFormatter.timeZone = TimeZone.current
            
            // Create a date for comparison that combines today's date with each time slot
            let todayFormatter = DateFormatter()
            todayFormatter.dateFormat = "yyyy-MM-dd h:mm a"
            todayFormatter.timeZone = TimeZone.current
            let todayString = dateFormatter.string(from: currentTime)
            
            print("DEBUG: Current time: \(timeFormatter.string(from: currentTime))")
            
            availableTimeSlots = defaultTimeSlots.filter { timeSlot in
                // Combine today's date with the time slot
                let slotDateString = "\(todayString) \(timeSlot)"
                if let slotDate = todayFormatter.date(from: slotDateString) {
                    // Add 30 minutes buffer to current time
                    let bufferTime = calendar.date(byAdding: .minute, value: 30, to: currentTime) ?? currentTime
                    print("DEBUG: Comparing slot \(timeSlot) with buffer time \(timeFormatter.string(from: bufferTime))")
                    return slotDate > bufferTime
                }
                return false
            }
            
            print("DEBUG: Available slots after time filtering: \(availableTimeSlots)")
        } else {
            print("DEBUG: Selected date is not today, showing all slots")
        }
        
        // Debug doctor data
        print("DEBUG: Doctor ID: \(doctor.id ?? "nil")")
        
        // Check for schedule data and blocked time slots
        if let scheduleData = doctor.schedule {
            print("DEBUG: Doctor schedule found")
            
            // Check if this day is a full day leave
            if let fullDayLeaves = scheduleData.fullDayLeaves {
                print("DEBUG: Full day leaves available: \(fullDayLeaves)")
                
                // Get the normalized date for comparison
                let selectedDateNormalized = calendar.startOfDay(for: selectedDate)
                
                // Check if the current date is in full day leaves
                for leaveDate in fullDayLeaves {
                    // Try to parse the leave date
                    if let date = parseDate(leaveDate) {
                        let leaveDateNormalized = calendar.startOfDay(for: date)
                        if calendar.isDate(selectedDateNormalized, inSameDayAs: leaveDateNormalized) {
                            print("DEBUG: Selected date is a full day leave")
                            availableTimeSlots = []
                            isLoading = false
                            return
                        }
                    } else if leaveDate == dateString {
                        // Also try to match the string format directly
                        print("DEBUG: Selected date is a full day leave (string match)")
                        availableTimeSlots = []
                        isLoading = false
                        return
                    }
                }
            }
            
            // Check for individual time slots blocked
            if let leaveTimeSlots = scheduleData.leaveTimeSlots {
                print("DEBUG: Blocked time slots available: \(leaveTimeSlots)")
                
                // Get the time slot strings for the selected date
                let blockedSlotsForDate = getBlockedSlotsForDate(selectedDate, leaveTimeSlots)
                print("DEBUG: Blocked slots for selected date: \(blockedSlotsForDate)")
                
                // Remove blocked time slots from available slots
                for blockedSlot in blockedSlotsForDate {
                    availableTimeSlots.removeAll { timeSlot in
                        return timeSlot == blockedSlot
                    }
                }
            }
        }
        
        // Check for existing appointments and set up real-time listener
        guard let doctorId = doctor.id else {
            isLoading = false
            return
        }
        
        // Set up a real-time listener for appointments on this date and doctor
        appointmentListener = db.collection("\(dbName)_appointments")
            .whereField("docId", isEqualTo: doctorId)
            .whereField("date", isEqualTo: dateString)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("DEBUG: Error listening for appointments: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("DEBUG: No appointment documents found")
                    return
                }
                
                print("DEBUG: Found \(documents.count) appointments in real-time")
                
                Task { @MainActor in
                    for document in documents {
                        let data = document.data()
                        if let bookedTime = data["time"] as? String {
                            self.removeBookedSlot(bookedTime)
                        }
                    }
                    
                    // If selected time is now unavailable, clear it
                    if !self.availableTimeSlots.contains(self.selectedTime) {
                        self.selectedTime = ""
                    }
                    
                    self.isLoading = false
                }
                
                // Also track changes for newly added appointments
                snapshot?.documentChanges.forEach { diff in
                    if diff.type == .added {
                        print("DEBUG: New appointment added")
                        if let bookedTime = diff.document.data()["time"] as? String {
                            Task { @MainActor in
                                self.removeBookedSlot(bookedTime)
                                
                                // If the user's selected time was just booked, clear it
                                if self.selectedTime == bookedTime {
                                    self.selectedTime = ""
                                }
                            }
                        }
                    }
                }
            }
    }
    
    // Helper function to determine if a date is in full day leaves
    private func isDateInFullDayLeaves(_ date: Date) -> Bool {
        guard let fullDayLeaves = doctor.schedule?.fullDayLeaves else {
            return false
        }
        
        let dateString = dateFormatter.string(from: date)
        
        // First try string matching
        if fullDayLeaves.contains(dateString) {
            return true
        }
        
        // Then try date matching
        let normalizedDate = calendar.startOfDay(for: date)
        for leaveDate in fullDayLeaves {
            if let parsedDate = parseDate(leaveDate) {
                let leaveDateNormalized = calendar.startOfDay(for: parsedDate)
                if calendar.isDate(normalizedDate, inSameDayAs: leaveDateNormalized) {
                    return true
                }
            }
        }
        
        // As a final check, fetch and check the raw Firebase data
        // This is a synchronous check so we need to use a cached result or check asynchronously
        // and update the UI later
        if let doctorId = doctor.id {
            let db = Firestore.firestore()
            
            // Check user defaults for a cached list of full day leaves
            let defaults = UserDefaults.standard
            let cachedLeavesKey = "fullDayLeaves_\(doctorId)"
            
            if let cachedLeaveTimestamps = defaults.array(forKey: cachedLeavesKey) as? [Double] {
                for timestamp in cachedLeaveTimestamps {
                    let leaveDate = Date(timeIntervalSince1970: timestamp)
                    if calendar.isDate(normalizedDate, inSameDayAs: leaveDate) {
                        return true
                    }
                }
            }
            
            // Start an async task to fetch and cache the full day leaves for future use
            Task {
                do {
                    let docRef = db.collection("hms4_doctors").document(doctorId)
                    let document = try await docRef.getDocument()
                    
                    if document.exists, let data = document.data(),
                       let scheduleData = data["schedule"] as? [String: Any],
                       let fullDayLeaves = scheduleData["fullDayLeaves"] as? [Any] {
                        
                        var leaveTimestamps: [Double] = []
                        
                        for leave in fullDayLeaves {
                            if let timestamp = leave as? Timestamp {
                                let leaveDate = timestamp.dateValue()
                                leaveTimestamps.append(leaveDate.timeIntervalSince1970)
                                
                                // If this leave date matches our query date, note it for UI update
                                if calendar.isDate(normalizedDate, inSameDayAs: leaveDate) {
                                    // Cache the result
                                    defaults.set(leaveTimestamps, forKey: cachedLeavesKey)
                                    
                                    // We found a match, but it's too late to affect the current UI drawing
                                    // The next time the view refreshes, it will use the cached value
                                    print("DEBUG: Found full day leave in async check, will update UI on next refresh")
                                }
                            }
                        }
                        
                        // Cache all the leave timestamps for future quick checks
                        defaults.set(leaveTimestamps, forKey: cachedLeavesKey)
                    }
                } catch {
                    print("DEBUG: Error checking full day leaves: \(error)")
                }
            }
        }
        
        return false
    }
    
    // Helper function to get blocked time slots for a specific date
    private func getBlockedSlotsForDate(_ date: Date, _ leaveTimeSlots: [String]) -> Set<String> {
        var blockedSlots = Set<String>()
        
        // Get the normalized date for comparison
        let normalizedDate = calendar.startOfDay(for: date)
        let dateString = dateFormatter.string(from: date)
        
        // Process time slots in two ways:
        // 1. Direct string matching for time slots (if they're stored as "9:00 AM")
        for slot in leaveTimeSlots {
            if defaultTimeSlots.contains(slot) {
                blockedSlots.insert(slot)
            }
        }
        
        // 2. Parse dates for time slots that might include date+time
        for slot in leaveTimeSlots {
            if let slotDate = parseDateTime(slot) {
                let slotDateNormalized = calendar.startOfDay(for: slotDate)
                
                // If the date part matches our target date
                if calendar.isDate(normalizedDate, inSameDayAs: slotDateNormalized) {
                    // Extract the time part
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "h:mm a"
                    let timeString = timeFormatter.string(from: slotDate)
                    
                    // Add to blocked slots
                    blockedSlots.insert(timeString)
                }
            }
        }
        
        return blockedSlots
    }
    
    // Helper function to parse a date string
    private func parseDate(_ dateString: String) -> Date? {
        // Try various date formats
        let formats = ["yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "MMMM d, yyyy"]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    // Helper function to parse a date+time string
    private func parseDateTime(_ dateTimeString: String) -> Date? {
        // Try various date+time formats
        let formats = ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd h:mm a"]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateTimeString) {
                return date
            }
        }
        
        return nil
    }
    
    private func isTimeSlotUnavailable(_ slot: String) -> Bool {
        // Check if date is in full day leaves
        if isDateInFullDayLeaves(selectedDate) {
            return true
        }
        
        // Check if the time slot is in doctor's leave time slots
        if let leaveTimeSlots = doctor.schedule?.leaveTimeSlots {
            let blockedSlots = getBlockedSlotsForDate(selectedDate, leaveTimeSlots)
            if blockedSlots.contains(slot) {
                return true
            }
        }
        
        // If it's today, check if the time has passed (with 30 min buffer)
        if calendar.isDateInToday(selectedDate) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            if let slotTime = timeFormatter.date(from: slot) {
                let currentTime = Date()
                let bufferTime = calendar.date(byAdding: .minute, value: 30, to: currentTime) ?? currentTime
                
                // Compare only the time components
                let slotComponents = calendar.dateComponents([.hour, .minute], from: slotTime)
                let bufferComponents = calendar.dateComponents([.hour, .minute], from: bufferTime)
                
                if let slotDate = calendar.date(from: slotComponents),
                   let bufferDate = calendar.date(from: bufferComponents) {
                    return slotDate <= bufferDate
                }
            }
        }
        
        return false
    }
    
    private func bookAppointment() {
        guard let doctorId = doctor.id,
              !selectedTime.isEmpty else {
            errorMessage = "Please select a time slot"
            showingError = true
            return
        }
        
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "yyyy-MM-dd h:mma"
        let startTime = selectedTime.components(separatedBy: " - ")[0]
        let combinedDateTimeString = "\(dateString) \(startTime)"
        let appointmentDateTime = timeFormatter.date(from: combinedDateTimeString.lowercased())
        
        let appointmentId = UUID().uuidString
        
        guard let patientId = UserDefaults.standard.string(forKey: "userId") else {
            errorMessage = "Patient ID not found"
            showingError = true
            isLoading = false
            return
        }
        
        // Check payment method from UserDefaults
        let paymentMethod = UserDefaults.standard.string(forKey: "selectedPaymentMethod") ?? ""
        
        // Set appointment status based on payment method
        let appointmentStatus: AppointmentData.AppointmentStatus
        if paymentMethod == "counter" {
            // For counter payments, set status to .noShow (WAITING) until admin confirms
            appointmentStatus = .noShow
        } else {
            // For online payments, set status to scheduled
            appointmentStatus = .scheduled
        }
        
        let appointmentData: [String: Any] = [
            "id": appointmentId,
            "patId": patientId,
            "patName": patient.name,
            "docId": doctorId,
            "docName": doctor.name,
            "patientRecordsId": patientId,
            "date": dateString,
            "time": startTime,
            "appointmentDateTime": appointmentDateTime as Any,
            "status": appointmentStatus.rawValue,
            "paymentStatus": paymentMethod == "counter" ? "pending" : "completed",
            "durationMinutes": 60,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp(),
            "database": dbName,
            "userType": UserDefaults.standard.string(forKey: "userType") ?? "patient"
        ]
        
        // Create transaction data
        let transactionId = UUID().uuidString
        let transactionData: [String: Any] = [
            "id": transactionId,
            "patientId": patientId,
            "doctorId": doctorId,
            "amount": consultationFee,
            "paymentMethod": paymentMethod,
            "paymentStatus": paymentMethod == "counter" ? "pending" : "completed",
            "appointmentId": appointmentId,
            "appointmentDate": dateString,
            "transactionDate": FieldValue.serverTimestamp(),
            "type": "consultation_fee"
        ]
        
        Task {
            do {
                let patientDoc = try await db.collection("\(dbName)_patients").document(patientId).getDocument()
                
                if !patientDoc.exists {
                    try await db.collection("\(dbName)_patients").document(patientId).setData([
                        "id": patientId,
                        "name": patient.name,
                        "email": patient.email,
                        "createdAt": FieldValue.serverTimestamp(),
                        "database": dbName,
                        "userType": "patient"
                    ])
                }
                
                // Store appointment data
                try await db.collection("\(dbName)_appointments").document(appointmentId).setData(appointmentData)
                
                // Store transaction data
                try await db.collection("\(dbName)_transactions").document(transactionId).setData(transactionData)
                
                // After successful booking, immediately remove the slot from available time slots
                await MainActor.run {
                    availableTimeSlots.removeAll { $0 == startTime }
                    isLoading = false
                    showingConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to book appointment: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}
