//
//  Theme.swift
//  HMS
//
//  Created by rjk on 21/04/25.
//


import SwiftUI

struct Theme {
    let primary: Color
    let background: Color
    let secondary: Color
    let tertiary: Color
    let text: Color
    let card: Color
    let border: Color
    let shadow: Color

    static let light = Theme(
        primary: Color(hex: "#1976D2"),
        background: Color(hex: "#F1F4F9"),
        secondary: Color(hex: "#DDDDDD"),
        tertiary: Color(hex: "#61AAF2"),
        text: Color.black,
        card: Color.white,
        border: Color(hex: "#CCCCCC"),
        shadow: Color.black.opacity(0.1)
    )

    static let dark = Theme(
        primary: Color(hex: "#1976D2"),
        background: Color(hex: "#151515"),
        secondary: Color(hex: "#585858"),
        tertiary: Color(hex: "#61AAF2"),
        text: Color.white,
        card: Color(hex: "#1F1F1F"),
        border: Color(hex: "#333333"),
        shadow: Color.black.opacity(0.6)
    )
}

// Hex Color Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24 & 0xFF, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (1, 1, 1, 1)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
