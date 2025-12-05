//
//  ProjectCanvasScreen.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/15/25.
//

import SwiftUI
import MetalKit

struct ProjectCanvasScreen: View {
    @State var project: Project
    @State private var audioPlayer = AudioPlayerManager()
    @State private var showChangeBackgroundSheet = false
    
    @State private var progress = 0.5
    @State private var primaryColor = Color.green
    private let start = Date.now
    
    var body: some View {
        ZStack {
            
            TimelineView(.animation) { tl in
                let time = start.distance(to: tl.date)
                let frequencyData = Array(audioPlayer.frequencyData.reversed())
                
                ProjectBackgroundView(
                    background: project.background,
                    time: time,
                    frequencyData: frequencyData
                )
            }
            .ignoresSafeArea()
            
        }
        .backgroundStyle(Color.background)
        .onAppear {
            guard let url = project.fileURL else {
                print("No file url found")
                return
            }
            
            audioPlayer.play(url: url)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("", systemImage: "paintbrush", role: .none) {
                    showChangeBackgroundSheet = true
                }
            }
            ToolbarItem(placement: .bottomBar) {
                ColorPicker("Primary", selection: $primaryColor)
            }
            ToolbarItem(placement: .bottomBar) {
                VStack(spacing: 8) {
                    Slider(value: $progress)
                        .tint(.white)
                        .defersSystemGestures(on: .all)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
        }
        .sheet(isPresented: $showChangeBackgroundSheet) {
            EditProjectBackgroundView(project: project)
                .presentationDetents([.medium])
        }
    }
    
}
