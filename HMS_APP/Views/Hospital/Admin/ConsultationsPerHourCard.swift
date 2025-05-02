//
//  ConsultationsPerHourCard.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI

struct ConsultationsPerHourCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    let currentConsults = 8
    let targetConsults = 10
    let percentComplete = 80.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Consultations")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                    
                    Text("\(currentConsults)/hr")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(currentTheme.secondary, lineWidth: 3)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(percentComplete) / 100)
                        .stroke(currentTheme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(currentTheme.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(percentComplete))% of target")
                        .font(.caption)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(targetConsults)")
                        .font(.caption.bold())
                        .foregroundColor(currentTheme.text.opacity(0.8))
                }
                
                ProgressView(value: Double(currentConsults), total: Double(targetConsults))
                    .tint(currentTheme.primary)
            }
        }
        .padding()
        .background(currentTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentTheme.border, lineWidth: 1)
        )
        .shadow(color: currentTheme.shadow, radius: 10, x: 0, y: 2)
    }
}
