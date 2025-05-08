//
//  InfoRow.swift
//  HMS_Admin
//
//  Created by rjk on 24/04/25.
//
import SwiftUI

struct StaffInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let theme: Theme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.primary)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.text.opacity(0.8))
                Text(value)
                    .font(.body)
                    .foregroundColor(theme.text)
            }
            Spacer()
        }
    }
}
