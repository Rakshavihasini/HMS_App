import Foundation
import FirebaseVertexAI
import FirebaseFirestore

// Question types that can be generated
enum QuestionType: String, Codable {
    case multipleChoice
    case singleChoice
    case text
    case boolean
}

// Structure for a single question
struct Question: Identifiable, Codable {
    let id: String
    let text: String
    let type: QuestionType
    let options: [String]?
    var answer: String?
}

// Structure for user's initial symptoms
struct InitialSymptoms: Codable {
    let symptoms: [String]
    let description: String?
}

// Structure for the final report
struct AssessmentReport: Codable {
    let possibleConditions: [String]
    let recommendations: [String]
    let urgencyLevel: String
    let followUpSteps: [String]
    var specializations: [String]? // Added for doctor specialization matching
}

// Recommendation for doctor consultation
struct DoctorRecommendation {
    let condition: String
    let specialization: String
    let doctors: [DoctorProfile]
}

struct UserProfile {
    var age: Int
    var gender: String
    var name: String
}

struct MedicalHistory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    var isSelected: Bool
}

struct Symptom: Identifiable {
    let id = UUID()
    let name: String
    var isSelected: Bool
}

enum CoughType: String, CaseIterable {
    case dry = "Dry cough"
    case wet = "Wet cough"
    case none = "No cough"
}

enum OnsetType: String, CaseIterable {
    case suddenly = "Suddenly"
    case gradually = "Gradually"
    case notSure = "Not sure"
}

@MainActor
class SymptomCheckerViewModel: ObservableObject {
    private let generativeModel: GenerativeModel
    private let db = Firestore.firestore()
    
    init() {
        // Initialize the Vertex AI service
        let vertex = VertexAI.vertexAI()
        // Create a GenerativeModel instance with the appropriate model
        self.generativeModel = vertex.generativeModel(modelName: "gemini-2.0-flash")
    }
    
    @Published var currentQuestionIndex = 0
    @Published var questions: [Question] = []
    @Published var initialSymptoms = InitialSymptoms(symptoms: [], description: nil)
    @Published var report: AssessmentReport?
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentStep = 1
    @Published var userProfile = UserProfile(age: 0, gender: "", name: "")
    @Published var selectedSymptoms: Set<String> = []
    @Published var selectedMedicalHistory: [MedicalHistory] = []
    @Published var coughType: CoughType = .none
    @Published var onsetType: OnsetType = .notSure
    @Published var recommendedDoctors: [DoctorProfile] = []
    @Published var isLoadingDoctors = false
    
    // Map common medical conditions to specializations
    private let conditionToSpecialization: [String: String] = [
        "Allergies": "Allergist",
        "Asthma": "Pulmonologist",
        "Arthritis": "Rheumatologist",
        "Bronchitis": "Pulmonologist",
        "Common Cold": "General Physician",
        "COVID-19": "Infectious Disease",
        "Depression": "Psychiatrist",
        "Diabetes": "Endocrinologist",
        "Flu": "General Physician",
        "Gastritis": "Gastroenterologist",
        "Heart Disease": "Cardiologist",
        "Hypertension": "Cardiologist",
        "Migraine": "Neurologist",
        "Pneumonia": "Pulmonologist",
        "Sinusitis": "Otolaryngologist",
        "Strep Throat": "Otolaryngologist",
        "Urinary Tract Infection": "Urologist"
    ]
    
    // Specialization mapping
    private let specializationMapping: [String: String] = [
        "Allergist": "Immunology",
        "Cardiologist": "Cardiology",
        "Dermatologist": "Dermatology",
        "Endocrinologist": "Endocrinology",
        "Gastroenterologist": "Gastroenterology",
        "General Physician": "General Physician",
        "Infectious Disease": "Infectious Disease",
        "Neurologist": "Neurology",
        "Otolaryngologist": "ENT",
        "Psychiatrist": "Psychiatry",
        "Pulmonologist": "Pulmonology",
        "Rheumatologist": "Rheumatology",
        "Urologist": "Urology"
    ]
    
    let commonSymptoms = [
        "Headache",
        "Cough",
        "Fever",
        "Sore throat",
        "Fatigue",
        "Body ache",
        "Nausea",
        "Dizziness"
    ]
    
    let medicalHistoryOptions = [
        MedicalHistory(name: "Overweight", icon: "figure.arms.open", isSelected: false),
        MedicalHistory(name: "Smoking", icon: "smoke", isSelected: false),
        MedicalHistory(name: "High BP", icon: "heart", isSelected: false),
        MedicalHistory(name: "High Cholesterol", icon: "drop", isSelected: false),
        MedicalHistory(name: "Diabetes", icon: "cross.case", isSelected: false),
        MedicalHistory(name: "Lung Disease", icon: "lungs", isSelected: false),
        MedicalHistory(name: "Recent Surgery", icon: "stethoscope", isSelected: false),
        MedicalHistory(name: "None", icon: "circle.slash", isSelected: false)
    ]
    
    // Generate questions based on initial symptoms
    func generateQuestions(symptoms: [String], description: String?) async {
        isLoading = true
        let prompt = """
        Based on the following symptoms: \(symptoms.joined(separator: ", "))
        Additional description: \(description ?? "None")
        Generate up to 5 relevant medical assessment questions in JSON format.
        Each question should have:
        - id: unique string
        - text: question text
        - type: "multipleChoice", "singleChoice", "text", or "boolean"
        - options: array of possible answers (for multiple/single choice)
        Questions should help narrow down the possible conditions and severity.
        
        Return ONLY a valid JSON array with no additional text.
        """
        
        do {
            let response = try await generativeModel.generateContent(prompt)
            guard let responseText = response.text else {
                throw NSError(domain: "SymptomChecker", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Failed to get response text"])
            }
            
            // Print the raw response for debugging
            print("RAW API RESPONSE: \(responseText)")
            
            // Try to extract JSON if response contains markdown code blocks
            let jsonText: String
            if responseText.contains("```json") && responseText.contains("```") {
                // Extract content between ```json and ``` markers
                let pattern = "```json\\s*(.+?)\\s*```"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
                   let match = regex.firstMatch(in: responseText, range: NSRange(responseText.startIndex..., in: responseText)) {
                    if let range = Range(match.range(at: 1), in: responseText) {
                        jsonText = String(responseText[range])
                    } else {
                        jsonText = responseText
                    }
                } else {
                    jsonText = responseText
                }
            } else {
                jsonText = responseText
            }
            
            // Clean the JSON (remove any non-JSON characters)
            let cleanedJson = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("CLEANED JSON: \(cleanedJson)")
            
            guard let jsonData = cleanedJson.data(using: .utf8) else {
                throw NSError(domain: "SymptomChecker", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
            }
            
            do {
                let decodedQuestions = try JSONDecoder().decode([Question].self, from: jsonData)
                self.questions = decodedQuestions
                self.isLoading = false
            } catch let decodingError {
                print("JSON DECODING ERROR: \(decodingError)")
                self.error = "JSON parsing error: \(decodingError.localizedDescription)\nRaw response: \(responseText)"
                self.isLoading = false
            }
        } catch let apiError {
            print("API ERROR: \(apiError)")
            self.error = "API error: \(apiError.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // Generate final assessment report
    func generateReport() async {
        isLoading = true
        let answersDescription = questions.map { question in
            "Q: \(question.text)\nA: \(question.answer ?? "No answer")"
        }.joined(separator: "\n")
        
        let prompt = """
        Based on the following symptoms and answers, generate a medical assessment report in JSON format:
        Initial Symptoms: \(initialSymptoms.symptoms.joined(separator: ", "))
        Initial Description: \(initialSymptoms.description ?? "None")
        
        Questionnaire Responses:
        \(answersDescription)
        
        Generate a report with:
        - possibleConditions: array of potential conditions
        - recommendations: array of recommendations
        - urgencyLevel: "Emergency", "Urgent", "Non-urgent", or "Self-care"
        - followUpSteps: array of next steps
        - specializations: array of medical specializations that would be relevant for these conditions
        
        Return ONLY a valid JSON object with no additional text.
        """
        
        do {
            let response = try await generativeModel.generateContent(prompt)
            guard let responseText = response.text else {
                throw NSError(domain: "SymptomChecker", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Failed to get response text"])
            }
            
            // Print the raw response for debugging
            print("RAW REPORT RESPONSE: \(responseText)")
            
            // Try to extract JSON if response contains markdown code blocks
            let jsonText: String
            if responseText.contains("```json") && responseText.contains("```") {
                // Extract content between ```json and ``` markers
                let pattern = "```json\\s*(.+?)\\s*```"
                if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
                   let match = regex.firstMatch(in: responseText, range: NSRange(responseText.startIndex..., in: responseText)) {
                    if let range = Range(match.range(at: 1), in: responseText) {
                        jsonText = String(responseText[range])
                    } else {
                        jsonText = responseText
                    }
                } else {
                    jsonText = responseText
                }
            } else {
                jsonText = responseText
            }
            
            // Clean the JSON (remove any non-JSON characters)
            let cleanedJson = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
            print("CLEANED REPORT JSON: \(cleanedJson)")
            
            guard let jsonData = cleanedJson.data(using: .utf8) else {
                throw NSError(domain: "SymptomChecker", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Failed to convert response to data"])
            }
            
            do {
                let decodedReport = try JSONDecoder().decode(AssessmentReport.self, from: jsonData)
                self.report = decodedReport
                self.isLoading = false
                
                // After generating report, fetch recommended doctors
                await fetchRecommendedDoctors()
            } catch let decodingError {
                print("REPORT JSON DECODING ERROR: \(decodingError)")
                self.error = "Report parsing error: \(decodingError.localizedDescription)\nRaw response: \(responseText)"
                self.isLoading = false
            }
        } catch let apiError {
            print("REPORT API ERROR: \(apiError)")
            self.error = "API error: \(apiError.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // Map conditions to specializations and fetch doctors
    func fetchRecommendedDoctors() async {
        guard let report = self.report else { return }
        
        // For now, just fetch all doctors without filtering by specialization
        do {
            // Fetch all doctors from the collection
            let snapshot = try await db.collection("hms4_doctors").getDocuments()
            
            print("DOCTORS: \(snapshot.documents)")
            let doctors = snapshot.documents.compactMap { document -> DoctorProfile? in
                let data = document.data()
                print(data)
                let id = document.documentID
                
                guard let name = data["name"] as? String,
                      let speciality = data["speciality"] as? String else {
                    return nil
                }
                
                let database = data["database"] as? String
                let age = data["age"] as? Int
                let appwriteUserId = data["appwriteUserId"] as? String
                let gender = data["gender"] as? String
                let lastActive = data["lastActive"] as? String
                let createdAt = data["createdAt"] as? Timestamp
                
                // Parse schedules
                var schedule: DoctorSchedules? = nil
                if let scheduleData = data["schedule"] as? [String: Any] {
                    print("DEBUG: Found schedule data for doctor \(id)")
                    
                    // Parse fullDayLeaves
                    var fullDayLeaves: [String]? = nil
                    if let fullDayLeavesData = scheduleData["fullDayLeaves"] as? [String] {
                        fullDayLeaves = fullDayLeavesData
                        print("DEBUG: Full day leaves from array: \(fullDayLeavesData)")
                    } else if let fullDayLeavesMap = scheduleData["fullDayLeaves"] as? [String: Any] {
                        // If it's stored as a map/dictionary
                        fullDayLeaves = Array(fullDayLeavesMap.keys)
                        print("DEBUG: Full day leaves from map: \(fullDayLeavesMap.keys)")
                    }
                    
                    // Parse leaveTimeSlots
                    var leaveTimeSlots: [String]? = nil
                    if let leaveTimeSlotsData = scheduleData["leaveTimeSlots"] as? [String] {
                        leaveTimeSlots = leaveTimeSlotsData
                        print("DEBUG: Leave time slots from array: \(leaveTimeSlotsData)")
                    } else if let leaveTimeSlotsMap = scheduleData["leaveTimeSlots"] as? [String: Any] {
                        // If it's stored as a map/dictionary
                        leaveTimeSlots = Array(leaveTimeSlotsMap.keys)
                        print("DEBUG: Leave time slots from map: \(leaveTimeSlotsMap.keys)")
                    }
                    
                    schedule = DoctorSchedules(fullDayLeaves: fullDayLeaves, leaveTimeSlots: leaveTimeSlots)
                }
                
                // Parse licenseDetails
                var licenseDetails: LicenseDetails? = nil
                if let licenseData = data["licenseDetails"] as? [String: Any] {
                    let councilName = licenseData["councilName"] as? String
                    let registrationNumber = licenseData["registrationNumber"] as? Int
                    let verificationStatus = licenseData["verificationStatus"] as? String
                    let verifiedAt = licenseData["verifiedAt"] as? Timestamp
                    let yearOfRegistration = licenseData["yearOfRegistration"] as? Int
                    licenseDetails = LicenseDetails(
                        councilName: councilName,
                        registrationNumber: registrationNumber,
                        verificationStatus: verificationStatus,
                        verifiedAt: verifiedAt,
                        yearOfRegistration: yearOfRegistration
                    )
                }
                
                return DoctorProfile(
                    id: id,
                    name: name,
                    speciality: speciality,
                    database: database,
                    age: age,
                    schedule: schedule,
                    appwriteUserId: appwriteUserId,
                    gender: gender,
                    licenseDetails: licenseDetails,
                    createdAt: createdAt,
                    lastActive: lastActive
                )
            }
            
            if !doctors.isEmpty {
                // Use the first condition as the representative condition
                let condition = report.possibleConditions.first ?? "Medical condition"
                
                // Create a single recommendation with all doctors
                self.recommendedDoctors = doctors
                
                // Print the recommended doctors to console
                printRecommendedDoctors()
            } else {
                print("No doctors found in the database.")
            }
        } catch {
            print("Error fetching doctors: \(error.localizedDescription)")
        }
    }
    
    // Helper function to get specialization based on condition
    private func getSpecializationForCondition(_ condition: String) -> String? {
        // Try exact match first
        if let specialization = conditionToSpecialization[condition] {
            return specialization
        }
        
        // Try partial match
        for (conditionKey, specialization) in conditionToSpecialization {
            if condition.lowercased().contains(conditionKey.lowercased()) ||
               conditionKey.lowercased().contains(condition.lowercased()) {
                return specialization
            }
        }
        
        // Default to General Practitioner if no match
        return "General Practitioner"
    }
    
    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            // Set a flag to indicate we're finalizing the assessment
            isLoading = true
            // Run the report generation
            Task {
                await generateReport()
            }
        }
    }
    
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    func nextStep() {
        if currentStep < 6 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    // Function to print recommended doctors to console for debugging
    func printRecommendedDoctors() {
        guard !recommendedDoctors.isEmpty else {
            print("No doctor recommendations available yet.")
            return
        }
        
        print("\n=== RECOMMENDED DOCTORS ===\n")
        for (index, doctor) in recommendedDoctors.enumerated() {
            print("RECOMMENDATION #\(index + 1)")
            print("For condition: \(doctor.speciality)")
            print("Specialization: \(doctor.speciality)")
            print("Recommended doctor:")
            
            print("  Dr. \(doctor.name)")
            print("     Speciality: \(doctor.speciality)")
            if let age = doctor.age { print("     Age: \(age)") }
            if let gender = doctor.gender { print("     Gender: \(gender)") }
            if let lastActive = doctor.lastActive { print("     Last Active: \(lastActive)") }
            if let licenseDetails = doctor.licenseDetails {
                print("     License Details:")
                if let council = licenseDetails.councilName { print("        Council: \(council)") }
                if let regNum = licenseDetails.registrationNumber { print("        Registration #: \(regNum)") }
                if let status = licenseDetails.verificationStatus { print("        Status: \(status)") }
                if let year = licenseDetails.yearOfRegistration { print("        Year: \(year)") }
                if let verifiedAt = licenseDetails.verifiedAt { print("        Verified At: \(verifiedAt.dateValue())") }
            }
            if let schedule = doctor.schedule {
                print("     Schedule:")
                if let fullDayLeaves = schedule.fullDayLeaves {
                    print("        Full Day Leaves: \(fullDayLeaves)")
                }
                if let leaveTimeSlots = schedule.leaveTimeSlots {
                    print("        Leave Time Slots: \(leaveTimeSlots)")
                }
            }
            if let appwriteUserId = doctor.appwriteUserId { print("     Appwrite User ID: \(appwriteUserId)") }
            if let database = doctor.database { print("     Database: \(database)") }
            print("")
        }
        print("----------------------------")
    }
    
    // Fetch doctors based on conditions
    func fetchDoctorsByConditions(_ conditions: [String]) async {
        self.isLoadingDoctors = true
        print("Fetching doctors for conditions: \(conditions)")
        
        // Common condition keywords to specialty mappings
        let conditionKeywords: [String: String] = [
            // Respiratory conditions
            "cough": "Pulmonology",
            "asthma": "Pulmonology",
            "bronchitis": "Pulmonology",
            "pneumonia": "Pulmonology",
            "respiratory": "Pulmonology",
            "lung": "Pulmonology",
            "breathing": "Pulmonology",
            "copd": "Pulmonology",
            
            // Cardiac conditions
            "heart": "Cardiology",
            "cardiac": "Cardiology",
            "chest pain": "Cardiology",
            "hypertension": "Cardiology",
            "blood pressure": "Cardiology",
            "cardiovascular": "Cardiology",
            "palpitation": "Cardiology",
            
            // Neurological conditions
            "migraine": "Neurology",
            "headache": "Neurology",
            "nerve": "Neurology",
            "seizure": "Neurology",
            "epilepsy": "Neurology",
            "stroke": "Neurology",
            "neurological": "Neurology",
            "brain": "Neurology",
            
            // Gastrointestinal conditions
            "stomach": "Gastroenterology",
            "gastritis": "Gastroenterology",
            "digestive": "Gastroenterology",
            "bowel": "Gastroenterology",
            "intestinal": "Gastroenterology",
            "acid reflux": "Gastroenterology",
            "ulcer": "Gastroenterology",
            "abdominal": "Gastroenterology",
            
            // ENT conditions
            "throat": "ENT",
            "ear": "ENT",
            "nose": "ENT",
            "sinus": "ENT",
            "sinusitis": "ENT",
            "tonsil": "ENT",
            "pharyngitis": "ENT",
            
            // Dermatological conditions
            "skin": "Dermatology",
            "rash": "Dermatology",
            "dermatitis": "Dermatology",
            "eczema": "Dermatology",
            "acne": "Dermatology",
            
            // Orthopedic conditions
            "bone": "Orthopedics",
            "joint": "Orthopedics",
            "fracture": "Orthopedics",
            "arthritis": "Orthopedics",
            "muscle": "Orthopedics",
            "back pain": "Orthopedics",
            "sprain": "Orthopedics",
            
            // General conditions
            "fever": "General Physician",
            "cold": "General Physician",
            "flu": "General Physician",
            "infection": "General Physician",
            "virus": "General Physician",
            "fatigue": "General Physician"
        ]
        
        // Extract candidate specialties based on condition keywords
        var targetSpecialties = Set<String>()
        
        // Process each condition against our keywords
        for condition in conditions {
            var matchFound = false
            
            // Look for keyword matches within the condition
            for (keyword, specialty) in conditionKeywords {
                if condition.lowercased().contains(keyword.lowercased()) {
                    targetSpecialties.insert(specialty)
                    matchFound = true
                    print("Matched condition '\(condition)' to specialty '\(specialty)' via keyword '\(keyword)'")
                }
            }
            
            // If no specific match found, add General Physician as fallback
            if !matchFound {
                targetSpecialties.insert("General Physician")
                print("No specific match for condition '\(condition)', defaulting to General Physician")
            }
        }
        
        // Always include General Physician as a fallback option
        targetSpecialties.insert("General Physician")
        
        print("Target specialties: \(targetSpecialties)")
        
        // Fetch doctors from Firestore
        do {
            let snapshot = try await db.collection("hms4_doctors").getDocuments()
            print("Found \(snapshot.documents.count) total doctors")
            
            var matchedDoctors: [DoctorProfile] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let id = document.documentID
                
                guard let name = data["name"] as? String,
                      let speciality = data["speciality"] as? String else {
                    continue
                }
                
                // Normalize the specialty string
                let normalizedSpecialty = speciality.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Check if this doctor's specialty matches any of our target specialties
                var isMatched = false
                for targetSpecialty in targetSpecialties {
                    // Check for partial matches in both directions to be more flexible
                    if normalizedSpecialty.lowercased().contains(targetSpecialty.lowercased()) ||
                       targetSpecialty.lowercased().contains(normalizedSpecialty.lowercased()) {
                        isMatched = true
                        print("Matched doctor: \(name) with specialty '\(normalizedSpecialty)' to target '\(targetSpecialty)'")
                        break
                    }
                }
                
                // Include General Physician by default when no specific match
                if !isMatched && normalizedSpecialty.lowercased().contains("general") {
                    isMatched = true
                    print("Including general physician: \(name)")
                }
                
                if isMatched {
                    // Parse schedule
                    var schedule: DoctorSchedules? = nil
                    if let scheduleData = data["schedule"] as? [String: Any] {
                        let fullDayLeaves = scheduleData["fullDayLeaves"] as? [String]
                        let leaveTimeSlots = scheduleData["leaveTimeSlots"] as? [String]
                        schedule = DoctorSchedules(fullDayLeaves: fullDayLeaves, leaveTimeSlots: leaveTimeSlots)
                    }
                    
                    // Parse licenseDetails
                    var licenseDetails: LicenseDetails? = nil
                    if let licenseData = data["licenseDetails"] as? [String: Any] {
                        let councilName = licenseData["councilName"] as? String
                        let registrationNumber = licenseData["registrationNumber"] as? Int
                        let verificationStatus = licenseData["verificationStatus"] as? String
                        let verifiedAt = licenseData["verifiedAt"] as? Timestamp
                        let yearOfRegistration = licenseData["yearOfRegistration"] as? Int
                        licenseDetails = LicenseDetails(
                            councilName: councilName,
                            registrationNumber: registrationNumber,
                            verificationStatus: verificationStatus,
                            verifiedAt: verifiedAt,
                            yearOfRegistration: yearOfRegistration
                        )
                    }
                    
                    let doctor = DoctorProfile(
                        id: id,
                        name: name,
                        speciality: speciality,
                        database: data["database"] as? String,
                        age: data["age"] as? Int,
                        schedule: schedule,
                        appwriteUserId: data["appwriteUserId"] as? String,
                        gender: data["gender"] as? String,
                        licenseDetails: licenseDetails,
                        createdAt: data["createdAt"] as? Timestamp,
                        lastActive: data["lastActive"] as? String
                    )
                    
                    matchedDoctors.append(doctor)
                }
            }
            
            print("Found \(matchedDoctors.count) matching doctors")
            
            // If no matching doctors found, try to find at least one general physician
            if matchedDoctors.isEmpty {
                print("No matches found, attempting to find any general physician")
                
                for document in snapshot.documents {
                    let data = document.data()
                    let id = document.documentID
                    
                    guard let name = data["name"] as? String,
                          let speciality = data["speciality"] as? String else {
                        continue
                    }
                    
                    if speciality.lowercased().contains("general") {
                        print("Found general physician as fallback: \(name)")
                        
                        // Create the doctor profile
                        let doctor = DoctorProfile(
                            id: id,
                            name: name,
                            speciality: speciality,
                            database: data["database"] as? String,
                            age: data["age"] as? Int,
                            schedule: nil,
                            appwriteUserId: data["appwriteUserId"] as? String,
                            gender: data["gender"] as? String,
                            licenseDetails: nil,
                            createdAt: data["createdAt"] as? Timestamp,
                            lastActive: data["lastActive"] as? String
                        )
                        
                        matchedDoctors.append(doctor)
                        break
                    }
                }
                
                // If still no doctors found, show any doctor
                if matchedDoctors.isEmpty && !snapshot.documents.isEmpty {
                    print("Still no matches, using first available doctor")
                    let document = snapshot.documents[0]
                    let data = document.data()
                    let id = document.documentID
                    
                    if let name = data["name"] as? String,
                       let speciality = data["speciality"] as? String {
                        
                        let doctor = DoctorProfile(
                            id: id,
                            name: name,
                            speciality: speciality,
                            database: data["database"] as? String,
                            age: data["age"] as? Int,
                            schedule: nil,
                            appwriteUserId: data["appwriteUserId"] as? String,
                            gender: data["gender"] as? String,
                            licenseDetails: nil,
                            createdAt: data["createdAt"] as? Timestamp,
                            lastActive: data["lastActive"] as? String
                        )
                        
                        matchedDoctors.append(doctor)
                    }
                }
            }
            
            await MainActor.run {
                self.recommendedDoctors = matchedDoctors
                self.isLoadingDoctors = false
            }
        } catch {
            print("Error fetching doctors: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingDoctors = false
            }
        }
    }
} 
