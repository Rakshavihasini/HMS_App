//
//  InfoRow.swift
//  HMS_Admin
//
//  Created by rjk on 24/04/25.
//
import SwiftUI

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let theme: Theme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(theme.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(theme.text)
            }
            Spacer()
        }
    }
}
