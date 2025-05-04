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
    let symptom: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(symptom)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct QuestionaireContentView: View {
    @StateObject private var viewModel = SymptomCheckerViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
//                Text("Symptom Checker")
//                    .font(.headline)
                
                Spacer()
            }
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
        .navigationBarHidden(true)
    }
}

struct InitialSymptomsView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    @State private var searchText = ""
    @State private var description = ""
    
    var filteredSymptoms: [String] {
        if searchText.isEmpty {
            return viewModel.commonSymptoms
        } else {
            return viewModel.commonSymptoms.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What symptoms are you experiencing?")
                .font(.title3)
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
            
            Text("Additional details:")
                .font(.headline)
                .padding(.horizontal)
            
            TextField("Describe your symptoms in detail (optional)", text: $description, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(height: 100)
                .padding(.horizontal)
            
            Button(action: {
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
            }) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedSymptoms.isEmpty && description.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .disabled(viewModel.selectedSymptoms.isEmpty && description.isEmpty)
            .padding(.horizontal)
        }
    }
}

struct QuestionnaireView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    @State private var answer: String = ""
    @State private var painLevel: Int = 5
    
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
    
    var progressValue: Double {
        guard !viewModel.questions.isEmpty else { return 0 }
        let value = Double(min(viewModel.currentQuestionIndex + 1, viewModel.questions.count))
        let total = Double(max(1, viewModel.questions.count))
        return min(value, total) / total
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            ProgressView(value: progressValue)
                .tint(.blue)
                .padding()
            
            Text(currentQuestion.text)
                .font(.title3)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            if isPainScaleQuestion {
                VStack(spacing: 20) {
                    Text("Pain Level: \(painLevel)")
                        .font(.headline)
                    
                    Text(painLevelDescription(for: painLevel))
                        .foregroundColor(painLevelColor(for: painLevel))
                    
                    Slider(value: Binding(
                        get: { Double(painLevel) },
                        set: { painLevel = Int($0) }
                    ), in: 0...10, step: 1)
                    .padding(.horizontal)
                    .accentColor(painLevelColor(for: painLevel))
                    
                    HStack {
                        Text("0").font(.caption)
                        Spacer()
                        Text("5").font(.caption)
                        Spacer()
                        Text("10").font(.caption)
                    }
                    .padding(.horizontal)
                    
                    Text(painLevelExplanation(for: painLevel))
                        .font(.caption)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        viewModel.questions[viewModel.currentQuestionIndex].answer = "\(painLevel)"
                        viewModel.nextQuestion()
                    }) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                }
            } else {
                switch currentQuestion.type {
                case .multipleChoice, .singleChoice:
                    VStack(spacing: 12) {
                        ForEach(currentQuestion.options ?? [], id: \.self) { option in
                            Button(action: {
                                viewModel.questions[viewModel.currentQuestionIndex].answer = option
                                viewModel.nextQuestion()
                            }) {
                                Text(option)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                case .boolean:
                    HStack(spacing: 20) {
                        ForEach(["Yes", "No"], id: \.self) { option in
                            Button(action: {
                                viewModel.questions[viewModel.currentQuestionIndex].answer = option
                                viewModel.nextQuestion()
                            }) {
                                Text(option)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                case .text:
                    VStack {
                        TextField("Enter your answer", text: $answer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button(action: {
                            viewModel.questions[viewModel.currentQuestionIndex].answer = answer
                            answer = ""
                            viewModel.nextQuestion()
                        }) {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .disabled(answer.isEmpty)
                        .padding(.horizontal)
                    }
                    
                default:
                    Text("Unsupported question type")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            
            Spacer()
            
            // Navigation buttons
            HStack {
                if viewModel.currentQuestionIndex > 0 {
                    Button("Back") {
                        viewModel.previousQuestion()
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding(.horizontal)
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with urgency level
                HStack {
                    Text("Assessment Results")
                        .font(.title2)
                        .fontWeight(.bold)
                    
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
                    }
                    
                    ForEach(report.possibleConditions, id: \.self) { condition in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.blue)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text(condition)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
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
                    }
                    
                    ForEach(report.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.green)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text(recommendation)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
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
                    }
                    
                    ForEach(report.followUpSteps, id: \.self) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("•")
                                .foregroundColor(.orange)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text(step)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Doctor Recommendations
                if !viewModel.recommendedDoctors.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person.text.rectangle")
                                .font(.title2)
                                .foregroundColor(.purple)
                            
                            Text("Recommended Doctors")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        ForEach(viewModel.recommendedDoctors.flatMap { $0.doctors.prefix(3) }, id: \.id) { doctor in
                            DoctorCardView(doctor: doctor)
                        }
                        
                        Button(action: {
                            // Add action to view all doctors
                        }) {
                            Text("View All Available Doctors")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                }
                
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }.padding(.horizontal)
                    //
                    //                    Button(action: {
                    //                        // Add action to consult doctor
                    //                    }) {
                    //                        HStack {
                    //                            Image(systemName: "video")
                    //                            Text("Consult Doctor")
                    //                        }
                    //                        .frame(maxWidth: .infinity)
                    //                        .padding()
                    //                        .background(Color.green)
                    //                        .foregroundColor(.white)
                    //                        .cornerRadius(10)
                    //                    }
                    //                }
                    //                .padding(.horizontal)
                    //                .padding(.bottom)
                }
            }
            .padding(.vertical)
        }
    }
}

// Doctor Card View for showing doctor recommendations
struct DoctorCardView: View {
    let doctor: DoctorProfile
    
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
            
            Button(action: {
                // Add action to book appointment
            }) {
                Text("Book")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct UrgencyBadge: View {
    let level: String
    
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
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(error)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Try Again") {
                // Add retry logic here
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

