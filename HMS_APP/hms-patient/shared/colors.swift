//
//  colors.swift
//  MediCareManager
//
//  Created by s1834 on 18/04/25.
//

import SwiftUI


extension Color {
    // Updated primary color to #1976D2
    static let medicareBlue = Color(hex: "1976D2")
    static let medicareLightBlue = Color(hex: "E3F2FD")
    static let medicareDarkBlue = Color(hex: "0D47A1")
    static let medicareGreen = Color(hex: "4CAF50")
    static let medicareRed = Color(hex: "F44336")
    static let medicareLightGray = Color(hex: "F5F5F5")
    static let medicareDarkGray = Color(hex: "424242")
}

extension View {
    func medicareCardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func medicareSectionTitle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.medicareBlue)
            .padding(.horizontal)
    }
}

// Separate extension for adaptive text color
extension View {
    // Simpler version of adaptiveTextColor that uses the environment directly
    func adaptiveTextColor() -> some View {
        modifier(AdaptiveTextColorModifier())
    }
}

struct AdaptiveTextColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content.foregroundColor(colorScheme == .dark ? .white : .black)
    }
}

// Environment key for current theme
struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = Theme.light
}

extension EnvironmentValues {
    var currentTheme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func withDynamicTheme() -> some View {
        self.modifier(DynamicThemeModifier())
    }
}

struct DynamicThemeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .environment(\.currentTheme, colorScheme == .dark ? Theme.dark : Theme.light)
    }
}

// Theme-aware color extensions
extension View {
    func primaryBackground() -> some View {
        self.modifier(PrimaryBackgroundModifier())
    }
    
    func themedCard() -> some View {
        self.modifier(ThemedCardModifier())
    }
}

struct PrimaryBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? Theme.dark.background : Theme.light.background)
    }
}

struct ThemedCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(colorScheme == .dark ? Theme.dark.card : Theme.light.card)
            .cornerRadius(12)
            .shadow(color: colorScheme == .dark ? Theme.dark.shadow : Theme.light.shadow, radius: 5, x: 0, y: 2)
    }
}
