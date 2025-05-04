//
//  DoctorSlotManagerView.swift
//  HMS_APP
//
//  Created by Rudra Pruthi on 02/05/25.
//


import SwiftUI
import FirebaseFirestore

// MARK: - Calendar View
struct CalendarView: View {
    @Binding var selectedDate: Date
    @Binding var fullDayLeaves: Set<Date>
    let leaveColor: Color
    let mainColor: Color
    let theme: Theme
    
    let calendar = Calendar.current
    @State private var currentMonth = Date()
    
    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }
    
    var body: some View {
        VStack {
            // Month navigation
            HStack {
                Button(action: {
                    if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
                        currentMonth = newMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(mainColor)
                }
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(mainColor)
                
                Spacer()
                
                Button(action: {
                    if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
                        currentMonth = newMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(mainColor)
                }
            }
            .padding(.horizontal, 8)
            
            // Days of the week header
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            
            // Calendar grid with placeholder for days from previous/next month
            let firstWeekday = calendar.component(.weekday, from: daysInMonth.first ?? Date())
            let leadingSpaces = firstWeekday - 1
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                // Leading empty spaces
                ForEach(0..<leadingSpaces, id: \.self) { _ in
                    Color.clear.frame(width: 38, height: 38)
                }
                
                // Days of the month
                ForEach(daysInMonth, id: \.self) { date in
                    let isSelected = calendar.isDate(selectedDate, inSameDayAs: date)
                    let isOnLeave = fullDayLeaves.contains { calendar.isDate($0, inSameDayAs: date) }
                    let isToday = calendar.isDateInToday(date)
                    
                    Button(action: {
                        selectedDate = date
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    isOnLeave ? leaveColor :
                                        isSelected ? theme.primary :
                                            Color.clear
                                )
                                .frame(width: 38, height: 38)
                            
                            Circle()
                                .strokeBorder(isToday && !isSelected && !isOnLeave ? Color.green : Color.clear, lineWidth: 2)
                                .frame(width: 38, height: 38)
                            
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 16, weight: isToday || isSelected ? .bold : .regular))
                                .foregroundColor(isSelected || isOnLeave ? .white : (isToday ? .green : theme.text))
                        }
                    }
                }
            }
            .padding(12)
            .background(theme.card)
            .cornerRadius(16)
            .shadow(color: theme.shadow, radius: 4)
        }
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Action Button
struct SlotActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(20)
        }
    }
}

// MARK: - Slot Section
struct SlotSection: View {
    let title: String
    let icon: String
    let slots: [String]
    let blockedSlots: Set<String>
    let isFullDayBlocked: Bool
    let leaveColor: Color
    let mainColor: Color
    let theme: Theme
    let onToggle: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(mainColor)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(mainColor)
            }
            .padding(.horizontal)
            
            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(slots, id: \.self) { slot in
                    SlotToggleButton(
                        time: slot,
                        isBlocked: blockedSlots.contains(slot) || isFullDayBlocked,
                        fullDayBlock: isFullDayBlocked,
                        leaveColor: leaveColor,
                        theme: theme,
                        onToggle: {
                            onToggle(slot)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Slot Toggle Button
struct SlotToggleButton: View {
    let time: String
    let isBlocked: Bool
    let fullDayBlock: Bool
    let leaveColor: Color
    let theme: Theme
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: fullDayBlock ? {} : onToggle) {
            HStack {
                Text(time)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(theme.text)
                Spacer()
                Image(systemName: isBlocked ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundColor(isBlocked ? leaveColor : .green)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isBlocked ? leaveColor.opacity(0.08) : Color.green.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isBlocked ? leaveColor.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(fullDayBlock ? 0.6 : 1)
        }
        .disabled(fullDayBlock)
    }
}

// MARK: - Main View

struct DoctorSlotManagerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // State variables
    @State private var selectedDate: Date = Date()
    @State private var fullDayLeaves: Set<Date> = []
    @State private var leaveTimeSlots: [Date: Set<String>] = [:]
    @State private var showUndoAlert: Bool = false
    @State private var lastAction: (date: Date, slots: Set<String>)? = nil
    @State private var actionType: ActionType = .none
    @State private var showSuccessToast: Bool = false
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // Services and data
    @State private var doctor: Doctor? = nil
    @State private var doctorId: String
    
    // MARK: - Initialization
    
    init() {
        // Initialize with the user ID from UserDefaults
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        _doctorId = State(initialValue: userId)
    }
    
    init(doctorId: String) {
        _doctorId = State(initialValue: doctorId)
    }
    
    init(doctor: Doctor) {
        self.init(doctorId: doctor.id)
        _doctor = State(initialValue: doctor)
        
        // If doctor has schedule data, initialize our state with it
        if let schedule = doctor.schedule {
            // Convert fullDayLeaves array to Set for our view
            if let fullDayLeaves = schedule.fullDayLeaves {
                _fullDayLeaves = State(initialValue: Set(fullDayLeaves))
            }
            
            // Convert the leave time slots array to our dictionary format
            if let leaveTimeSlots = schedule.leaveTimeSlots {
                var slotsDict: [Date: Set<String>] = [:]
                
                // Group time slots by day and convert to time strings
                for leaveSlot in leaveTimeSlots {
                    // Get just the date part (without time)
                    let calendar = Calendar.current
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: leaveSlot)
                    if let dateOnly = calendar.date(from: dateComponents) {
                        // Convert the time to a string (HH:MM AM/PM format)
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateFormat = "hh:mm a"
                        let timeString = timeFormatter.string(from: leaveSlot)
                        
                        // Add to dictionary
                        var existingSlots = slotsDict[dateOnly, default: []]
                        existingSlots.insert(timeString)
                        slotsDict[dateOnly] = existingSlots
                    }
                }
                
                _leaveTimeSlots = State(initialValue: slotsDict)
            }
        }
    }
    
    private var theme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    // Define the specific color for leaves - #61aaf2
    let leaveColor = Color(hex: "#61aaf2")
    // Define red color specifically for leave markings
    let redLeaveColor = Color(hex: "#FF0000")
    
    // Action type enum
    enum ActionType {
        case none, blockSlot, blockFullDay
    }
    
    let timeSlots = [
        "09:00 AM", "09:30 AM", "10:00 AM",
        "10:30 AM", "11:00 AM", "11:30 AM",
        "03:00 PM", "03:30 PM", "04:00 PM",
        "04:30 PM", "05:00 PM", "05:30 PM"
    ]
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                // Header
                HStack(alignment: .center) {
                    Text("Manage Slots")
                        .font(.title)
                        .foregroundColor(theme.text)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Doctor name display (if available)
                        if let doctor = doctor {
                            HStack {
                                Text("Dr. \(doctor.name)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.text)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        // Date selector with legend
                        VStack(alignment: .leading, spacing: 14) {
                            CalendarView(
                                selectedDate: $selectedDate,
                                fullDayLeaves: $fullDayLeaves,
                                leaveColor: redLeaveColor,
                                mainColor: leaveColor,
                                theme: theme
                            )
                            
                            // Legend
                            HStack(spacing: 20) {
                                LegendItem(color: theme.primary, text: "Selected")
                                LegendItem(color: redLeaveColor, text: "Leave")
                                LegendItem(color: .green, text: "Today")
                            }
                            .padding(.vertical, 6)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Action buttons for selected date
                        HStack {
                            let isFullDayBlocked = fullDayLeaves.contains(where: {
                                Calendar.current.isDate($0, inSameDayAs: selectedDate)
                            })
                            
                            // Block/Unblock Full Day
                            SlotActionButton(
                                icon: isFullDayBlocked ? "calendar.badge.minus" : "calendar.badge.plus",
                                title: isFullDayBlocked ? "Remove Full Day Leave" : "Mark Full Day Leave",
                                color: leaveColor,
                                action: {
                                    toggleFullDayLeave(for: selectedDate)
                                }
                            )
                            
                            Spacer()
                            
                            // Quick Actions Menu
                            Menu {
                                Button(action: {
                                    blockMorningSlots()
                                }) {
                                    Label("Mark Morning Leave", systemImage: "sunrise")
                                }
                                
                                Button(action: {
                                    blockAfternoonSlots()
                                }) {
                                    Label("Mark Afternoon Leave", systemImage: "sunset")
                                }
                                
                                Button(action: {
                                    clearAllSlots()
                                }) {
                                    Label("Clear All Leaves", systemImage: "trash")
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "ellipsis.circle.fill")
                                    Text("Actions")
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Time Slots Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Manage Time Slots")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.text)
                                .padding(.horizontal)
                            
                            // Morning slots
                            SlotSection(
                                title: "Morning Slots",
                                icon: "sunrise.fill",
                                slots: Array(timeSlots.prefix(6)),
                                blockedSlots: leaveTimeSlots[selectedDate, default: []],
                                isFullDayBlocked: fullDayLeaves.contains(where: {
                                    Calendar.current.isDate($0, inSameDayAs: selectedDate)
                                }),
                                leaveColor: redLeaveColor,
                                mainColor: leaveColor,
                                theme: theme,
                                onToggle: { slot in
                                    toggleTimeSlot(for: selectedDate, time: slot)
                                }
                            )
                            
                            // Afternoon slots
                            SlotSection(
                                title: "Afternoon Slots",
                                icon: "sunset.fill",
                                slots: Array(timeSlots.suffix(6)),
                                blockedSlots: leaveTimeSlots[selectedDate, default: []],
                                isFullDayBlocked: fullDayLeaves.contains(where: {
                                    Calendar.current.isDate($0, inSameDayAs: selectedDate)
                                }),
                                leaveColor: redLeaveColor,
                                mainColor: leaveColor,
                                theme: theme,
                                onToggle: { slot in
                                    toggleTimeSlot(for: selectedDate, time: slot)
                                }
                            )
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 15)
                    }
                    
                    
                    // Bottom buttons
                    HStack(spacing: 16) {
                        // Undo button
                        Button(action: {
                            undoLastAction()
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Undo")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(lastAction != nil ? leaveColor.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundColor(lastAction != nil ? leaveColor : .gray)
                            .cornerRadius(20)
                        }
                        .disabled(lastAction == nil)
                        
                        // Save button
                        Button(action: { saveChanges() }) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(leaveColor)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    .background(theme.background)
                }
            }
            // Toast message
            if showSuccessToast {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(leaveColor)
                        Text("Leave schedule saved successfully!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.text)
                        Spacer()
                    }
                    .padding()
                    .background(theme.card)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: leaveColor))
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.card)
                            .frame(width: 80, height: 80)
                            .shadow(radius: 5)
                    )
            }
            
            // Error toast
            if showError {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.text)
                        Spacer()
                    }
                    .padding()
                    .background(theme.card)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .navigationBarHidden(true)
        .background(theme.background)
        .onAppear {
            loadLocalData()
        }
        .alert(isPresented: $showUndoAlert) {
            Alert(
                title: Text("Changes Undone"),
                message: Text("Your previous leave changes have been reversed."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Data Management Functions
    
    /// Loads doctor schedule from UserDefaults
    func loadLocalData() {
        isLoading = true
        
        let defaults = UserDefaults.standard
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Load full day leaves from UserDefaults
        if let savedFullDayLeavesStrings = defaults.stringArray(forKey: "doctor_\(doctorId)_fullDayLeaves") {
            let savedFullDayLeaves = savedFullDayLeavesStrings.compactMap { dateFormatter.date(from: $0) }
            fullDayLeaves = Set(savedFullDayLeaves)
        }
        
        // Load time slots from UserDefaults
        var loadedLeaveTimeSlots = [Date: Set<String>]()
        if let savedSlotsDict = defaults.dictionary(forKey: "doctor_\(doctorId)_leaveTimeSlots") as? [String: [String]] {
            for (dateString, slots) in savedSlotsDict {
                if let date = dateFormatter.date(from: dateString) {
                    loadedLeaveTimeSlots[date] = Set(slots)
                }
            }
        }
        leaveTimeSlots = loadedLeaveTimeSlots
        
        // If no data is found and no doctor is provided, create sample data
        if fullDayLeaves.isEmpty && leaveTimeSlots.isEmpty && doctor == nil {
            // Create sample data for first-time users
            let calendar = Calendar.current
            var sampleFullDayLeaves = Set<Date>()
            
            // Add some sample full day leaves
            if let date1 = calendar.date(byAdding: .day, value: 3, to: Date()),
               let date2 = calendar.date(byAdding: .day, value: 7, to: Date()) {
                sampleFullDayLeaves.insert(date1)
                sampleFullDayLeaves.insert(date2)
            }
            
            // Add some sample time slot leaves
            var sampleLeaveTimeSlots = [Date: Set<String>]()
            if let date = calendar.date(byAdding: .day, value: 1, to: Date()) {
                sampleLeaveTimeSlots[date] = ["09:00 AM", "09:30 AM", "10:00 AM"]
            }
            
            // Update state with sample data
            self.fullDayLeaves = sampleFullDayLeaves
            self.leaveTimeSlots = sampleLeaveTimeSlots
            
            // Save sample data to UserDefaults
            saveToUserDefaults()
        }
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    // Add this function to convert from view format to Doctor model format
    /// Converts the current view data to a Doctor.Schedule object
    private func createDoctorSchedule() -> Doctor.Schedule {
        // Convert fullDayLeaves Set to Array
        let fullDayLeavesArray = Array(fullDayLeaves)
        
        // Convert leaveTimeSlots dictionary to array of Date objects with times
        var leaveTimeSlotsArray: [Date] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        
        for (date, slots) in leaveTimeSlots {
            let dateString = dateFormatter.string(from: date)
            
            for slot in slots {
                // Create a combined date+time string
                if let timeDate = timeFormatter.date(from: slot) {
                    let calendar = Calendar.current
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
                    
                    // Get date components
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    
                    // Add time components
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    // Create the combined date
                    if let combinedDate = calendar.date(from: dateComponents) {
                        leaveTimeSlotsArray.append(combinedDate)
                    }
                }
            }
        }
        
        return Doctor.Schedule(
            leaveTimeSlots: leaveTimeSlotsArray,
            fullDayLeaves: fullDayLeavesArray
        )
    }

    /// Saves the doctor's leave schedule to UserDefaults and prints data for future Firebase integration
    func saveChanges() {
        isLoading = true
        
        // Save data to UserDefaults
        saveToUserDefaults()
        
        // Convert view data to Doctor model format
        let doctorSchedule = createDoctorSchedule()
        
        // Convert fullDayLeaves to the format that would be sent to Firebase
        var fullDayLeavesDict: [String: Bool] = [:]
        for date in fullDayLeaves {
            let key = dateKey(from: date)
            fullDayLeavesDict[key] = true
        }
        
        // Convert leaveTimeSlots to the format that would be sent to Firebase
        var leaveTimeSlotsDict: [String: [String: Bool]] = [:]
        for (date, slots) in leaveTimeSlots {
            if !slots.isEmpty {
                let key = dateKey(from: date)
                var slotsDict: [String: Bool] = [:]
                for slot in slots {
                    slotsDict[slot] = true
                }
                leaveTimeSlotsDict[key] = slotsDict
            }
        }
        
        // MARK: - FIREBASE INTEGRATION POINT
        // Print the data in the format that would be sent to Firebase
        print("\n\n// ----- DATA FOR FIREBASE INTEGRATION ----- //")
        print("Doctor ID: \(doctorId)")
        print("Full Day Leaves: \(fullDayLeavesDict)")
        print("Leave Time Slots: \(leaveTimeSlotsDict)")
        print("// To integrate with Firebase, send this data to Firestore")
        print("// Example Firebase code:")
        print("let docRef = db.collection(\"doctors\").document(\"\(doctorId)\")")
        print("docRef.updateData([")
        print("    \"schedules.fullDayLeaves\": \(fullDayLeavesDict),")
        print("    \"schedules.leaveTimeSlots\": \(leaveTimeSlotsDict)")
        print("])")
        print("\n// Doctor model format:")
        print("// Full day leaves count: \(doctorSchedule.fullDayLeaves?.count ?? 0)")
        print("// Leave time slots count: \(doctorSchedule.leaveTimeSlots?.count ?? 0)")
        print("// ----- END OF FIREBASE INTEGRATION DATA ----- //\n\n")
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.showSuccessToast = true
            self.lastAction = nil
            self.actionType = .none
            
            // Hide toast after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showSuccessToast = false
            }
        }
    }
    
    /// Helper function to save data to UserDefaults
    private func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Save full day leaves as strings
        let fullDayLeavesStrings = fullDayLeaves.map { dateFormatter.string(from: $0) }
        defaults.set(fullDayLeavesStrings, forKey: "doctor_\(doctorId)_fullDayLeaves")
        
        // Save time slots as dictionary
        var timeSlotsDict: [String: [String]] = [:]
        for (date, slots) in leaveTimeSlots {
            if !slots.isEmpty {
                let dateString = dateFormatter.string(from: date)
                timeSlotsDict[dateString] = Array(slots)
            }
        }
        defaults.set(timeSlotsDict, forKey: "doctor_\(doctorId)_leaveTimeSlots")
        
        // Force save
        defaults.synchronize()
    }
    
    // MARK: - Helper Functions
    
    /// Converts a Date to a date-only string key (YYYY-MM-DD)
    private func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - UI Action Functions
    
    /// Toggles a time slot between blocked and available
    func toggleTimeSlot(for date: Date, time: String) {
        // Save current state for undo
        let currentSlots = leaveTimeSlots[date, default: []]
        lastAction = (date: date, slots: currentSlots)
        actionType = .blockSlot
        
        // Apply the change
        var set = currentSlots
        if set.contains(time) {
            set.remove(time)
        } else {
            set.insert(time)
        }
        leaveTimeSlots[date] = set
    }
    
    /// Toggles a full day leave for a specific date
    func toggleFullDayLeave(for date: Date) {
        // Save current state for undo
        let currentSlots = leaveTimeSlots[date, default: []]
        lastAction = (date: date, slots: currentSlots)
        actionType = .blockFullDay
        
        // Apply the change
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        if fullDayLeaves.contains(where: { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }) {
            // Remove the date
            fullDayLeaves = fullDayLeaves.filter { !Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
            leaveTimeSlots[normalizedDate] = []
        } else {
            // Add the date
            fullDayLeaves.insert(normalizedDate)
            leaveTimeSlots[normalizedDate] = Set(timeSlots)
        }
    }
    
    /// Blocks all morning slots for the selected date
    func blockMorningSlots() {
        // Save current state for undo
        let currentSlots = leaveTimeSlots[selectedDate, default: []]
        lastAction = (date: selectedDate, slots: currentSlots)
        actionType = .blockSlot
        
        // Add morning slots to blocked slots
        var set = currentSlots
        for slot in timeSlots.prefix(6) {
            set.insert(slot)
        }
        leaveTimeSlots[selectedDate] = set
    }
    
    /// Blocks all afternoon slots for the selected date
    func blockAfternoonSlots() {
        // Save current state for undo
        let currentSlots = leaveTimeSlots[selectedDate, default: []]
        lastAction = (date: selectedDate, slots: currentSlots)
        actionType = .blockSlot
        
        // Add afternoon slots to blocked slots
        var set = currentSlots
        for slot in timeSlots.suffix(6) {
            set.insert(slot)
        }
        leaveTimeSlots[selectedDate] = set
    }
    
    /// Clears all blocked slots for the selected date
    func clearAllSlots() {
        // Save current state for undo
        let currentSlots = leaveTimeSlots[selectedDate, default: []]
        lastAction = (date: selectedDate, slots: currentSlots)
        actionType = .blockSlot
        
        // Clear all slots for the selected date
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        
        // Filter out the normalized date from full day leaves
        fullDayLeaves = fullDayLeaves.filter { !Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
        leaveTimeSlots[normalizedDate] = []
    }
    
    /// Undoes the last action performed on the schedule
    func undoLastAction() {
        guard let lastAction = lastAction else { return }
        
        switch actionType {
        case .blockFullDay:
            let normalizedDate = Calendar.current.startOfDay(for: lastAction.date)
            if fullDayLeaves.contains(where: { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }) {
                fullDayLeaves = fullDayLeaves.filter { !Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
            } else {
                fullDayLeaves.insert(normalizedDate)
            }
        case .blockSlot:
            // Just restore the previous state
            break
        case .none:
            return
        }
        
        leaveTimeSlots[lastAction.date] = lastAction.slots
        self.lastAction = nil
        actionType = .none
        showUndoAlert = true
    }
}

// MARK: - Preview
struct DoctorSlotManagerView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorSlotManagerView(doctorId: "preview_doctor_id")
    }
}
