//
//  ContentView.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/13/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) var context
    
    var body: some View {
        ProjectsScreen()
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
