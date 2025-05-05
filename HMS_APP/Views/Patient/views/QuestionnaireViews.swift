import SwiftUI

struct SymptomSelectionView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Select all symptoms that apply")
                .font(.system(size: 24, weight: .bold))
                .padding(.horizontal)
                .padding(.top, 8)
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("OR")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Text("Just tell us in sentences")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal)
                
                Text("E.g. I have cough and I'm burning up")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.horizontal)
            }
            .padding(.top, 8)
        }
        .padding(.vertical)
    }
}

struct MedicalHistoryView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Please select the medical history applicable to you")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.horizontal)
                
                Text("YOU CAN SELECT MULTIPLE OPTIONS")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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
        .padding(.vertical)
    }
}

struct MedicalHistoryButton: View {
    let option: MedicalHistory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .blue : .gray)
                Text(option.name)
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
            )
        }
        .foregroundColor(isSelected ? .blue : .primary)
    }
}

struct CoughTypeView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Which of these describes your cough?")
                .font(.system(size: 24, weight: .bold))
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(CoughType.allCases, id: \.self) { type in
                    Button(action: { viewModel.coughType = type }) {
                        HStack {
                            Text(type.rawValue)
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                            if viewModel.coughType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.coughType == type ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
                        )
                    }
                    .foregroundColor(viewModel.coughType == type ? .blue : .primary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct OnsetView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("How did your cough start?")
                .font(.system(size: 24, weight: .bold))
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(OnsetType.allCases, id: \.self) { type in
                    Button(action: { viewModel.onsetType = type }) {
                        Text(type.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .stroke(viewModel.onsetType == type ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
                            )
                            .foregroundColor(viewModel.onsetType == type ? .blue : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct SummaryView: View {
    @ObservedObject var viewModel: SymptomCheckerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Summary of Your Symptoms")
                .font(.system(size: 24, weight: .bold))
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.selectedSymptoms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Symptoms:")
                            .font(.system(size: 18, weight: .semibold))
                        ForEach(Array(viewModel.selectedSymptoms), id: \.self) { symptom in
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.blue)
                                Text(symptom)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                }
                
                if !viewModel.selectedMedicalHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medical History:")
                            .font(.system(size: 18, weight: .semibold))
                        ForEach(viewModel.selectedMedicalHistory) { condition in
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.blue)
                                Text(condition.name)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                }
                
                if viewModel.coughType != .none {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cough Details:")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Type: \(viewModel.coughType.rawValue)")
                            .font(.system(size: 16))
                        Text("Onset: \(viewModel.onsetType.rawValue)")
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {}) {
                Text("Get Assessment")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .disabled(viewModel.selectedSymptoms.isEmpty && viewModel.selectedMedicalHistory.isEmpty)
        }
        .padding(.vertical)
    }
} 
