//
//  CustomTextField.swift
//  HMS
//
//  Created by rjk on 21/04/25.
//


import SwiftUI

struct CustomTextField: View {
    @Environment(\.colorScheme) var colorScheme
    
    var placeholder: String
    var isSecure: Bool
    @Binding var text: String
    var errorMessage: String? // Optional error message
    
    @State private var isTextHidden: Bool = true // State variable that toggles visibility of the text (for secure fields)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) { // Use VStack to stack text field and error message
            ZStack {
                // Background adapts to color scheme
                (colorScheme == .dark ? Color(UIColor.systemGray5) : Color.white)
                    .cornerRadius(6)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.3),
                            radius: 4, x: 0, y: 2)
                
                HStack {
                    
                    // Conditional text field or secure text field
                    if isSecure {
                        Group {
                            if isTextHidden {
                                SecureField("", text: $text, prompt: Text(placeholder)
                                    .foregroundColor(colorScheme == .dark ? .gray : .gray)
                                    .font(.system(size: 12)))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                TextField("", text: $text, prompt: Text(placeholder)
                                    .foregroundColor(colorScheme == .dark ? .gray : .gray)
                                    .font(.system(size: 12)))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textContentType(.password)
                            }
                        }
                        .padding(.horizontal, 10)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    } else {
                        TextField("", text: $text, prompt: Text(placeholder)
                            .foregroundColor(colorScheme == .dark ? .gray : .gray)
                            .font(.system(size: 12)))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 10)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    // Toggle button for showing/hiding password text
                    if isSecure {
                        Button(action: {
                            isTextHidden.toggle()
                        }) {
                            Image(systemName: isTextHidden ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(colorScheme == .dark ? .gray : .gray)
                        }
                        .padding(.trailing, 15)
                    }
                }
                .frame(height: 40)
                .font(.system(size: 16))
            }
            
            // Optional error message
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .frame(height: errorMessage != nil ? 60 : 40) // Adjust height based on error presence
    }
}
