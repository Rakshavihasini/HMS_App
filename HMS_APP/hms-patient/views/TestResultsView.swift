//
//  TestResultsView.swift
//  hms-patient
//
//  Created by s1834 on 23/04/25.
//

import SwiftUI

struct TestResultsView: View {
    let patient: Patient
    
    var body: some View {
        List {
            ForEach(["Blood Work (05/10/2023)", "X-Ray Chest (04/22/2023)"], id: \.self) { test in
                NavigationLink(destination: TestDetailView(testName: test)) {
                    Text(test)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct TestDetailView: View {
    let testName: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(testName)
                    .font(.title)
                    .padding(.bottom)
                
                if testName.contains("Blood Work") {
                    BloodWorkResultsView()
                } else if testName.contains("X-Ray") {
                    XRayResultsView()
                }
                
                Button(action: {}) {
                    Text("Download Full Report")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.medicareBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Test Results")
    }
}

struct BloodWorkResultsView: View {
    var body: some View {
        VStack(spacing: 10) {
            ResultRow(title: "Glucose", value: "98 mg/dL", range: "70-99", isNormal: true)
            ResultRow(title: "Cholesterol", value: "185 mg/dL", range: "<200", isNormal: true)
            ResultRow(title: "HDL", value: "45 mg/dL", range: ">40", isNormal: true)
            ResultRow(title: "LDL", value: "110 mg/dL", range: "<100", isNormal: false)
            ResultRow(title: "Triglycerides", value: "150 mg/dL", range: "<150", isNormal: false)
        }
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    let range: String
    let isNormal: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text("Reference: \(range)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .bold()
                .foregroundColor(isNormal ? .medicareGreen : .medicareRed)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct XRayResultsView: View {
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
            
            Text("Findings:")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
            
            Text("No acute cardiopulmonary findings. The lungs are clear. The cardiac silhouette is normal in size. No pleural effusion or pneumothorax.")
                .padding(.top, 4)
        }
    }
}
