//
//  SearchBar.swift
//  HMS_Admin
//
//  Created by rjk on 24/04/25.
//
import SwiftUI

struct SearchBar: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search", text: $text)
                .padding(.vertical, 8)
                .padding(.horizontal, 4) // Add horizontal padding for text field
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray5))
        .cornerRadius(10)
    }
}
