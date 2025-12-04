//
//  soundbiteApp.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/13/25.
//

import SwiftUI
import SwiftData

@main
struct soundbiteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [AudioRecording.self, Project.self])
    }
}
