//
//  Components.swift
//  MediCareManager
//
//  Created by s1834 on 22/04/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DoctorRow: View {
    let doctor: Doctor
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.medicareBlue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(doctor.name)
                    .font(.headline)
                
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("0.2%")
                }
                .font(.caption)
            }
            
            Spacer()
            
            Text("Available")
                .font(.caption)
                .padding(5)
                .background(Color.medicareGreen.opacity(0.2))
                .foregroundColor(.medicareGreen)
                .cornerRadius(5)
        }
        .padding(.vertical, 8)
    }
}

struct SharedReminderCard: View {
    let title: String
    let time: String
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .medicareGreen : .gray)
            
            VStack(alignment: .leading) {
                Text(title)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if !isCompleted {
                Button(action: {}) {
                    Text("Snooze")
                        .font(.caption)
                        .padding(5)
                        .background(Color.medicareLightBlue)
                        .cornerRadius(5)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct PatientDocumentPicker: UIViewControllerRepresentable {
    var onDocumentPicked: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(onDocumentPicked: onDocumentPicked)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .png, .jpeg], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                onDocumentPicked(url)
            }
        }
    }
}

