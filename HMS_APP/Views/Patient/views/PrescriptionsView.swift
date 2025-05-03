//
//  PrescriptionsView.swift
//  hms-patient
//
//  Created by s1834 on 23/04/25.
//

import SwiftUI

struct PrescriptionsView: View {
    let patient: Patient
    
    var body: some View {
        List {
            ForEach(["Metformin 500mg", "Lisinopril 10mg"], id: \.self) { med in
                VStack(alignment: .leading) {
                    Text(med)
                        .font(.headline)
                    Text("1 tab daily • Started 03/15/2022")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}
