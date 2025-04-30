//
//  SummaryCard.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI

struct SummaryCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(currentTheme.text.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Text(value)
                .font(.title3.bold())
                .foregroundColor(currentTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 12).fill(currentTheme.card))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(currentTheme.border, lineWidth: 1)
        )
        .shadow(color: currentTheme.shadow, radius: 5)
    }
}
