import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreFirebase

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
                            
                            Text("15 YEARS")
                                .font(.subheadline)
                                .foregroundColor(themePurple)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Text("₹1000")
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
                Button(action: bookAppointment) {
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
        .alert(isPresented: $showingConfirmation) {
            Alert(
                title: Text("Appointment Booked"),
                message: Text("Your appointment with \(doctor.name) on \(formattedDate()) at \(selectedTime) has been confirmed."),
                dismissButton: .default(Text("OK")) {
                    shouldNavigateBack = true
                }
            )
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
    
    private func fetchAvailableTimeSlots() {
        isLoading = true
        
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
        
        // Fetch the raw schedule data from Firebase to see what's actually stored
        if let doctorId = doctor.id {
            Task {
                do {
                    print("DEBUG: Fetching raw schedule data for doctor \(doctorId)")
                    let db = Firestore.firestore()
                    let docRef = db.collection("hms4_doctors").document(doctorId)
                    let document = try await docRef.getDocument()
                    
                    if document.exists, let data = document.data() {
                        if let scheduleData = data["schedule"] as? [String: Any] {
                            print("DEBUG: Raw schedule data from Firebase: \(scheduleData)")
                            
                            // Print detailed info about fullDayLeaves
                            if let fullDayLeaves = scheduleData["fullDayLeaves"] {
                                print("DEBUG: fullDayLeaves type: \(type(of: fullDayLeaves))")
                                print("DEBUG: fullDayLeaves value: \(fullDayLeaves)")
                                
                                if let fullDayLeavesArray = fullDayLeaves as? [Any] {
                                    for (index, leave) in fullDayLeavesArray.enumerated() {
                                        print("DEBUG: fullDayLeaves[\(index)] type: \(type(of: leave))")
                                        print("DEBUG: fullDayLeaves[\(index)] value: \(leave)")
                                    }
                                }
                                
                                if let fullDayLeavesDict = fullDayLeaves as? [String: Any] {
                                    for (key, value) in fullDayLeavesDict {
                                        print("DEBUG: fullDayLeaves[\"\(key)\"] type: \(type(of: value))")
                                        print("DEBUG: fullDayLeaves[\"\(key)\"] value: \(value)")
                                    }
                                }
                            } else {
                                print("DEBUG: fullDayLeaves is nil")
                            }
                            
                            // Print detailed info about leaveTimeSlots
                            if let leaveTimeSlots = scheduleData["leaveTimeSlots"] {
                                print("DEBUG: leaveTimeSlots type: \(type(of: leaveTimeSlots))")
                                print("DEBUG: leaveTimeSlots value: \(leaveTimeSlots)")
                                
                                if let leaveTimeSlotsArray = leaveTimeSlots as? [Any] {
                                    for (index, slot) in leaveTimeSlotsArray.enumerated() {
                                        print("DEBUG: leaveTimeSlots[\(index)] type: \(type(of: slot))")
                                        print("DEBUG: leaveTimeSlots[\(index)] value: \(slot)")
                                    }
                                }
                                
                                if let leaveTimeSlotsDict = leaveTimeSlots as? [String: Any] {
                                    for (key, value) in leaveTimeSlotsDict {
                                        print("DEBUG: leaveTimeSlots[\"\(key)\"] type: \(type(of: value))")
                                        print("DEBUG: leaveTimeSlots[\"\(key)\"] value: \(value)")
                                    }
                                }
                            } else {
                                print("DEBUG: leaveTimeSlots is nil")
                            }
                            
                            // Immediately use the raw data to update our view
                            // This is a fallback in case our DoctorProfile model doesn't parse the data correctly
                            await MainActor.run {
                                // Handle fullDayLeaves
                                if let fullDayLeaves = scheduleData["fullDayLeaves"] as? [Any] {
                                    // Check for Timestamps which is what SlotManagerView uses
                                    for leave in fullDayLeaves {
                                        if let timestamp = leave as? Timestamp {
                                            let leaveDate = timestamp.dateValue()
                                            if calendar.isDate(leaveDate, inSameDayAs: selectedDate) {
                                                print("DEBUG: Found matching full day leave timestamp for selected date")
                                                availableTimeSlots = []
                                                isLoading = false
                                                return
                                            }
                                        }
                                    }
                                }
                                
                                // Handle leaveTimeSlots
                                if let leaveTimeSlots = scheduleData["leaveTimeSlots"] as? [Any] {
                                    for slot in leaveTimeSlots {
                                        if let timestamp = slot as? Timestamp {
                                            let slotDate = timestamp.dateValue()
                                            if calendar.isDate(slotDate, inSameDayAs: selectedDate) {
                                                let timeFormatter = DateFormatter()
                                                timeFormatter.dateFormat = "h:mm a"
                                                let timeString = timeFormatter.string(from: slotDate)
                                                print("DEBUG: Found blocked time slot: \(timeString)")
                                                availableTimeSlots.removeAll { $0 == timeString }
                                            }
                                        }
                                    }
                                    
                                    // Now also handle the timestamps we see in the debug logs by converting them directly
                                    for (index, slot) in leaveTimeSlots.enumerated() {
                                        if let timestamp = slot as? Timestamp {
                                            let slotDate = timestamp.dateValue()
                                            if calendar.isDate(slotDate, inSameDayAs: selectedDate) {
                                                // Format the time to match our available time slots format
                                                let timeFormatter = DateFormatter()
                                                timeFormatter.dateFormat = "h:mm a"
                                                let timeString = timeFormatter.string(from: slotDate)
                                                print("DEBUG: Processing timestamp[\(index)]: \(timestamp.seconds) -> \(timeString)")
                                                
                                                // Remove this slot from available slots
                                                availableTimeSlots.removeAll { slot in
                                                    // Try exact match first
                                                    if slot == timeString {
                                                        print("DEBUG: Removed blocked slot (exact match): \(slot)")
                                                        return true
                                                    }
                                                    
                                                    // Try case-insensitive match
                                                    if slot.lowercased() == timeString.lowercased() {
                                                        print("DEBUG: Removed blocked slot (case-insensitive): \(slot)")
                                                        return true
                                                    }
                                                    
                                                    // Try alternative format (with/without leading zero)
                                                    let alternativeFormatter = DateFormatter()
                                                    alternativeFormatter.dateFormat = "h:mm a"
                                                    if let time = timeFormatter.date(from: timeString) {
                                                        let altTimeString = alternativeFormatter.string(from: time)
                                                        if slot == altTimeString {
                                                            print("DEBUG: Removed blocked slot (alternative format): \(slot)")
                                                            return true
                                                        }
                                                    }
                                                    
                                                    return false
                                                }
                                            }
                                        }
                                    }
                                }
                                isLoading = false
                            }
                        } else {
                            print("DEBUG: No schedule data found in the doctor document")
                        }
                    } else {
                        print("DEBUG: Doctor document not found")
                    }
                } catch {
                    print("DEBUG: Error fetching doctor document: \(error)")
                }
            }
        }
        
        // Check for existing appointments
        Task {
            do {
                print("DEBUG: Querying Firebase for doctorId: \(doctor.id ?? "nil") and date: \(dateString)")
                
                let snapshot = try await db.collection("\(dbName)_appointments")
                    .whereField("doctorId", isEqualTo: doctor.id ?? "")
                    .whereField("date", isEqualTo: dateString)
                    .getDocuments()
                
                print("DEBUG: Found \(snapshot.documents.count) existing appointments")
                
                for document in snapshot.documents {
                    if let bookedTime = document.data()["time"] as? String {
                        print("DEBUG: Found booked time slot: \(bookedTime)")
                        availableTimeSlots.removeAll { $0.contains(bookedTime) }
                    }
                }
                
                print("DEBUG: Final available slots: \(availableTimeSlots)")
                
                if !availableTimeSlots.contains(selectedTime) {
                    selectedTime = ""
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("DEBUG: Error fetching appointments: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to fetch time slots: \(error.localizedDescription)"
                    showingError = true
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
            "status": AppointmentData.AppointmentStatus.scheduled.rawValue,
            "durationMinutes": 60,
            "reason": reason,
            "createdAt": FieldValue.serverTimestamp(),
            "database": dbName,
            "userType": UserDefaults.standard.string(forKey: "userType") ?? "patient"
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
                
                try await db.collection("\(dbName)_appointments").document(appointmentId).setData(appointmentData)
                
                await MainActor.run {
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
