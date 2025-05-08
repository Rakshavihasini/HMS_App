//
//  ContentView.swift
//  SymptomChecker
//
//  Created by Prasanjit Panda on 22/04/25.
//

import SwiftUI
import FirebaseCore
import FirebaseVertexAI

// Share this component across the app
struct SymptomButton: View {
    @Environment(\.colorScheme) var colorScheme
    let symptom: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(symptom)
                    .foregroundColor(isSelected ? (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary) : (colorScheme == .dark ? .white : .primary))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary) : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        }
    }
}

struct QuestionaireContentView: View {
    @StateObject private var viewModel = SymptomCheckerViewModel()
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                (colorScheme == .dark ? Theme.dark.background : Theme.light.background)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Title centered
                    Text("Symptom Checker")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    if viewModel.isLoading {
                        Spacer()
                        VStack {
                            ProgressView()
                                .padding(.bottom, 10)
                            Text("Processing...")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else if let error = viewModel.error {
                        ErrorView(error: error)
                    } else if viewModel.report != nil {
                        ReportView(report: viewModel.report!, viewModel: viewModel)
                    } else if viewModel.questions.isEmpty {
                        InitialSymptomsView(viewModel: viewModel)
                    } else {
                        QuestionnaireView(viewModel: viewModel)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct InitialSymptomsView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    @State private var searchText = ""
    @State private var description = ""
    @State private var showValidationAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var filteredSymptoms: [String] {
        if searchText.isEmpty {
            return viewModel.commonSymptoms
        } else {
            return viewModel.commonSymptoms.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var isValidInput: Bool {
        !viewModel.selectedSymptoms.isEmpty || description.count >= 10
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What symptoms are you experiencing?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.horizontal)
            
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) {
                    ForEach(filteredSymptoms, id: \.self) { symptom in
                        SymptomButton(
                            symptom: symptom,
                            isSelected: viewModel.selectedSymptoms.contains(symptom),
                            action: {
                                if viewModel.selectedSymptoms.contains(symptom) {
                                    viewModel.selectedSymptoms.remove(symptom)
                                } else {
                                    viewModel.selectedSymptoms.insert(symptom)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional details:")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .padding(.horizontal)
                
                TextField("Describe your symptoms in detail (minimum 10 characters)", text: $description, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 100)
                    .padding(.horizontal)
                
                if !description.isEmpty && description.count < 10 {
                    Text("Please provide at least 10 characters")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            
            Button(action: {
                if isValidInput {
                    let symptoms = Array(viewModel.selectedSymptoms)
                    viewModel.initialSymptoms = InitialSymptoms(
                        symptoms: symptoms,
                        description: description.isEmpty ? nil : description
                    )
                    Task {
                        await viewModel.generateQuestions(
                            symptoms: symptoms,
                            description: description.isEmpty ? nil : description
                        )
                    }
                } else {
                    showValidationAlert = true
                }
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValidInput ? (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary) : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .disabled(!isValidInput)
            .padding(.horizontal)
            .alert(isPresented: $showValidationAlert) {
                Alert(
                    title: Text("Invalid Input"),
                    message: Text("Please either select symptoms or provide a detailed description (minimum 10 characters)."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct QuestionnaireView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    @State private var answer = ""
    @State private var painLevel = 5
    @State private var showValidationAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var currentQuestion: Question {
        guard viewModel.currentQuestionIndex < viewModel.questions.count else {
            return Question(id: "error", text: "Error", type: .text, options: nil)
        }
        return viewModel.questions[viewModel.currentQuestionIndex]
    }
    
    var isPainScaleQuestion: Bool {
        let questionText = currentQuestion.text.lowercased()
        return (questionText.contains("pain") || questionText.contains("scale")) && 
               (questionText.contains("0") && questionText.contains("10")) &&
               currentQuestion.type == .singleChoice
    }
    
    var isValidAnswer: Bool {
        switch currentQuestion.type {
        case .text:
            return answer.count >= 3
        case .boolean, .singleChoice, .multipleChoice:
            return true
        }
    }
    
    var progressValue: Double {
        guard !viewModel.questions.isEmpty else { return 0 }
        return Double(min(viewModel.currentQuestionIndex + 1, viewModel.questions.count)) / Double(max(1, viewModel.questions.count))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Top navigation with progress indicator
            VStack(spacing: 12) {
                // Progress indicator with navigation buttons
                HStack {
                    if viewModel.currentQuestionIndex > 0 {
                        Button(action: {
                            viewModel.previousQuestion()
                            answer = ""
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .foregroundColor(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.currentQuestionIndex + 1)/\(viewModel.questions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                ProgressView(value: progressValue)
                    .tint(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
            }
            .padding(.bottom, 10)
            
            Text(currentQuestion.text)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            if isPainScaleQuestion {
                painScaleView
            } else {
                switch currentQuestion.type {
                case .multipleChoice, .singleChoice:
                    optionsView
                case .boolean:
                    booleanView
                case .text:
                    textInputView
                }
            }
            
            Spacer()
        }
        .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
    }
    
    private var painScaleView: some View {
        VStack(spacing: 20) {
            Text("Pain Level: \(painLevel)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(painLevelDescription(for: painLevel))
                .foregroundColor(painLevelColor(for: painLevel))
                .font(.system(size: 16))
            
            Slider(value: Binding(
                get: { Double(painLevel) },
                set: { painLevel = Int($0) }
            ), in: 0...10, step: 1)
            .padding(.horizontal)
            .accentColor(painLevelColor(for: painLevel))
            
            HStack {
                Text("No Pain").font(.caption).foregroundColor(colorScheme == .dark ? .white : .primary)
                Spacer()
                Text("Severe").font(.caption).foregroundColor(colorScheme == .dark ? .white : .primary)
                Spacer()
                Text("Worst").font(.caption).foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            .padding(.horizontal)
            
            Text(painLevelExplanation(for: painLevel))
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white : .gray)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            continueButton
        }
    }
    
    private var optionsView: some View {
        VStack(spacing: 12) {
            ForEach(currentQuestion.options ?? [], id: \.self) { option in
                Button(action: {
                    viewModel.questions[viewModel.currentQuestionIndex].answer = option
                    viewModel.nextQuestion()
                }) {
                    Text(option)
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary, lineWidth: 1.5)
                        )
                }
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
        }
        .padding(.horizontal)
    }
    
    private var booleanView: some View {
        HStack(spacing: 20) {
            ForEach(["Yes", "No"], id: \.self) { option in
                Button(action: {
                    viewModel.questions[viewModel.currentQuestionIndex].answer = option
                    viewModel.nextQuestion()
                }) {
                    Text(option)
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary, lineWidth: 1.5)
                        )
                }
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
        }
        .padding(.horizontal)
    }
    
    private var textInputView: some View {
        VStack(spacing: 12) {
            TextField("Enter your answer (minimum 3 characters)", text: $answer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if !answer.isEmpty && answer.count < 3 {
                Text("Please provide at least 3 characters")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            continueButton
        }
    }
    
    private var continueButton: some View {
        Button(action: {
            if isValidAnswer {
                if isPainScaleQuestion {
                    viewModel.questions[viewModel.currentQuestionIndex].answer = "\(painLevel)"
                } else {
                    viewModel.questions[viewModel.currentQuestionIndex].answer = answer
                }
                viewModel.nextQuestion()
                answer = ""
            } else {
                showValidationAlert = true
            }
        }) {
            Text("Continue")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isValidAnswer ? (colorScheme == .dark ? Theme.dark.primary : Theme.light.primary) : Color.gray)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .disabled(!isValidAnswer)
        .padding(.horizontal)
        .alert(isPresented: $showValidationAlert) {
            Alert(
                title: Text("Invalid Input"),
                message: Text("Please provide a valid answer."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func painLevelColor(for level: Int) -> Color {
        switch level {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        default:
            return .red
        }
    }
    
    func painLevelDescription(for level: Int) -> String {
        switch level {
        case 0:
            return "No Pain"
        case 1...3:
            return "Mild Pain"
        case 4...6:
            return "Moderate Pain"
        case 7...9:
            return "Severe Pain"
        case 10:
            return "Worst Pain Possible"
        default:
            return ""
        }
    }
    
    func painLevelExplanation(for level: Int) -> String {
        switch level {
        case 0:
            return "No pain at all."
        case 1...3:
            return "Pain is present but does not limit daily activities."
        case 4...6:
            return "Pain interferes with some activities and may require medication."
        case 7...9:
            return "Pain makes it difficult to concentrate and perform normal activities."
        case 10:
            return "Excruciating pain that completely incapacitates."
        default:
            return ""
        }
    }
}

struct ReportView: View {
    let report: AssessmentReport
    @ObservedObject var viewModel: SymptomCheckerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with urgency level
                HStack {
                    Text("Assessment Results")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Spacer()
                    
                    UrgencyBadge(level: report.urgencyLevel)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Possible Conditions Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Possible Conditions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    ForEach(report.possibleConditions, id: \.self) { condition in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.blue)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text(condition)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Recommendations Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "list.clipboard")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Recommendations")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    ForEach(report.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.green)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text(recommendation)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Next Steps Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "arrow.forward.circle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Next Steps")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    ForEach(report.followUpSteps, id: \.self) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.orange)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text(step)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Doctor Recommendations
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        Text("Recommended Doctors")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    if viewModel.isLoadingDoctors {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if viewModel.recommendedDoctors.isEmpty {
                        Text("Loading recommended doctors...")
                            .foregroundColor(.secondary)
                            .padding()
                            .onAppear {
                                Task {
                                    // Fetch doctors based on possible conditions
                                    await viewModel.fetchDoctorsByConditions(report.possibleConditions)
                                }
                            }
                    } else {
                        ForEach(viewModel.recommendedDoctors, id: \.id) { doctor in
                            DoctorCardView(doctor: doctor)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Disclaimer
                Text("This assessment is for informational purposes only and does not constitute medical advice. Please consult with a healthcare professional.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .multilineTextAlignment(.center)
                
                // Action buttons
                HStack(spacing: 15) {
                    Button(action: {
                        // Add action to save report
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save Report")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }.padding(.horizontal)
                }
            }
            .padding(.vertical)
            .onAppear {
                // Trigger doctor recommendations when the report appears
                Task {
                    await viewModel.fetchDoctorsByConditions(report.possibleConditions)
                }
            }
        }
    }
}

// Doctor Card View for showing doctor recommendations
struct DoctorCardView: View {
    let doctor: DoctorProfile
    @State private var navigateToBooking = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.purple.opacity(0.7))
                .padding(4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Dr. \(doctor.name)")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(doctor.speciality)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let gender = doctor.gender {
                    Text(gender)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            NavigationLink(destination: 
                BookAppointmentView(
                    doctor: doctor,
                    patient: Patient(
                        id: UserDefaults.standard.string(forKey: "userId") ?? "",
                        name: UserDefaults.standard.string(forKey: "userName") ?? "Patient",
                        email: UserDefaults.standard.string(forKey: "userEmail") ?? ""
                    )
                )
            ) {
                Text("Book")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct UrgencyBadge: View {
    let level: String
    @Environment(\.colorScheme) var colorScheme
    
    var color: Color {
        switch level {
        case "Emergency": return .red
        case "Urgent": return .orange
        case "Non-urgent": return .yellow
        default: return .green
        }
    }
    
    var icon: String {
        switch level {
        case "Emergency": return "exclamationmark.triangle.fill"
        case "Urgent": return "exclamationmark.circle.fill"
        case "Non-urgent": return "clock.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(level)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

struct ErrorView: View {
    let error: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(error)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Try Again") {
                // Add retry logic here
            }
            .padding()
            .background(colorScheme == .dark ? Theme.dark.primary : Theme.light.primary)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
    }
}

#Preview {
    ContentView()
}

