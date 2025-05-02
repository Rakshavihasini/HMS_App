import SwiftUI

struct SymptomSelectionView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select all symptoms that apply")
                .font(.title2)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 10) {
                    ForEach(viewModel.commonSymptoms, id: \.self) { symptom in
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
            
            Text("OR,")
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Text("Just tell us in sentences.")
                .font(.headline)
                .padding(.horizontal)
            
            Text("E.g. I have cough and I'm burning up.")
                .foregroundColor(.gray)
                .italic()
                .padding(.horizontal)
        }
    }
}

struct MedicalHistoryView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Please select the medical history applicable to you")
                .font(.title2)
                .padding(.horizontal)
            
            Text("YOU CAN SELECT MULTIPLE OPTIONS")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(viewModel.medicalHistoryOptions) { option in
                    MedicalHistoryButton(
                        option: option,
                        isSelected: viewModel.selectedMedicalHistory.contains(where: { $0.id == option.id }),
                        action: {
                            if let index = viewModel.selectedMedicalHistory.firstIndex(where: { $0.id == option.id }) {
                                viewModel.selectedMedicalHistory.remove(at: index)
                            } else {
                                viewModel.selectedMedicalHistory.append(option)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MedicalHistoryButton: View {
    let option: MedicalHistory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: option.icon)
                    .font(.system(size: 24))
                Text(option.name)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .foregroundColor(isSelected ? .blue : .primary)
    }
}

struct CoughTypeView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Which of these describes your cough?")
                .font(.title2)
                .padding(.horizontal)
            
            ForEach(CoughType.allCases, id: \.self) { type in
                Button(action: { viewModel.coughType = type }) {
                    HStack {
                        Text(type.rawValue)
                            .foregroundColor(.blue)
                        Spacer()
                        if viewModel.coughType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct OnsetView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How did your cough start?")
                .font(.title2)
                .padding(.horizontal)
            
            ForEach(OnsetType.allCases, id: \.self) { type in
                Button(action: { viewModel.onsetType = type }) {
                    Text(type.rawValue)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Capsule()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SummaryView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Summary of Your Symptoms")
                .font(.title2)
                .padding(.horizontal)
            
            // Display selected symptoms
            if !viewModel.selectedSymptoms.isEmpty {
                Text("Selected Symptoms:")
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(Array(viewModel.selectedSymptoms), id: \.self) { symptom in
                    Text("• \(symptom)")
                        .padding(.horizontal)
                }
            }
            
            // Display medical history
            if !viewModel.selectedMedicalHistory.isEmpty {
                Text("Medical History:")
                    .font(.headline)
                    .padding(.horizontal)
                ForEach(viewModel.selectedMedicalHistory) { condition in
                    Text("• \(condition.name)")
                        .padding(.horizontal)
                }
            }
            
            // Display cough details if applicable
            if viewModel.coughType != .none {
                Text("Cough Type: \(viewModel.coughType.rawValue)")
                    .padding(.horizontal)
                Text("Onset: \(viewModel.onsetType.rawValue)")
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Get Assessment")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
        }
    }
} 
