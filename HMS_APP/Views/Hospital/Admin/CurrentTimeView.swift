//
//  CurrentTimeView.swift
//  HMS_Admin
//
//  Created by s1834 on 25/04/25.
//

import SwiftUI

struct CurrentTimeView: View {
    @State private var currentTime = ""
    @State private var currentDate = ""
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text(currentTime)
                .fontWeight(.semibold)
                .foregroundColor(currentTheme.text)
            
            Text(currentDate)
                .font(.caption)
                .foregroundColor(currentTheme.text.opacity(0.6))
        }
        .onAppear {
            updateTime()
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                updateTime()
            }
        }
    }
    
    private func updateTime() {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        currentTime = timeFormatter.string(from: Date())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d"
        currentDate = dateFormatter.string(from: Date())
    }
}
