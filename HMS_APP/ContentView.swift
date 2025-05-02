//
//  ContentView.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 30/04/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var hell = PatientDetails()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Button(action:{
                Task{
                    hell.fetchPatients()
                }
            }){
                Text("Click")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
