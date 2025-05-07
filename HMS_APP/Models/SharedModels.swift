//
//  SharedModels.swift
//  HMS_APP
//
//  Created by admin34 on 28/04/25.
//

import SwiftUI

// Shared enum for time range selection across the app
enum TimeRange {
    case day, week, month
}

// Shared view for time range selection
struct TimeRangeSelector1: View {
    @Binding var selectedRange: TimeRange
    @Environment(\.colorScheme) var colorScheme
    
    var currentTheme: Theme {
        colorScheme == .dark ? Theme.dark : Theme.light
    }
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            Text("Day").tag(TimeRange.day)
            Text("Week").tag(TimeRange.week)
            Text("Month").tag(TimeRange.month)
        }
        .pickerStyle(.segmented)
        .tint(currentTheme.tertiary)
    }
} 
