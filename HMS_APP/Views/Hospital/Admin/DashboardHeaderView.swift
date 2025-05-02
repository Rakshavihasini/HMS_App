//
//  DashboardHeaderView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI

struct DashboardHeaderView: View {
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hospital Dashboard")
                        .font(.title2.bold())
                        .foregroundColor(currentTheme.text)
                    
                    Text("Good morning, Dr. Smith")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
                
                Spacer()
                
                Image("doctor_avatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(currentTheme.card, lineWidth: 2)
                    )
            }
            
            HeaderSearchBar(text: $searchText)
        }
        .padding()
    }
}

struct HeaderSearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(currentTheme.text.opacity(0.6))
            
            TextField("Search patients, doctors...", text: $text)
                .font(.subheadline)
                .foregroundColor(currentTheme.text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(currentTheme.text.opacity(0.6))
                }
            }
        }
        .padding(12)
        .background(currentTheme.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(currentTheme.border, lineWidth: 1)
        )
    }
}
