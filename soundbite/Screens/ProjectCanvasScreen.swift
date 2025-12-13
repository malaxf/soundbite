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
    @State private var showExportProgressView = false
    
    @State private var progress = 0.5
    @State private var primaryColor = Color.green
    private let start = Date.now
    
    @State private var isExporting = false
    @State private var exportError: Error?
    
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
            
            if isExporting {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                    Text("Rendering & Exporting...")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            
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
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "arrow.down.to.line", role: .none) {
                    performExport()
                }
            }
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
    
    
    private func performExport() {
        guard let audioURL = project.fileURL else { return }
        
        isExporting = true
        showExportProgressView = true
        
        Task {
            do {
                let manager = ProjectExportManager()
                let fileManager = FileManager.default
                
                // Setup temporary paths
                let tempDir = fileManager.temporaryDirectory
                let videoOnlyURL = tempDir.appendingPathComponent("temp_video.mp4")
                let finalURL = tempDir.appendingPathComponent("soundbite_export_\(Date().timeIntervalSince1970).mp4")
                
                // Cleanup previous runs
                if fileManager.fileExists(atPath: videoOnlyURL.path()) { try fileManager.removeItem(at: videoOnlyURL) }
                if fileManager.fileExists(atPath: finalURL.path()) { try fileManager.removeItem(at: finalURL) }
                
                // Step A: Render Visuals (Silent)
                print("Rendering visuals...")
                try await manager.export(project: project, to: videoOnlyURL)
                
                // Step B: Merge Audio
                print("Merging audio...")
                try await manager.mergeAudio(videoURL: videoOnlyURL, audioURL: audioURL, outputURL: finalURL)
                
                // Step C: Save to Photos
                print("Saving to library...")
                try await manager.saveToCameraRoll(fileURL: finalURL)
                
                // Cleanup
                try? fileManager.removeItem(at: videoOnlyURL)
                // Optional: keep final file or delete it? Usually delete after saving to Photos.
                try? fileManager.removeItem(at: finalURL)
                
                print("Export Complete")
                
            } catch {
                print("Export Error: \(error.localizedDescription)")
                self.exportError = error
            }
            
            isExporting = false
            showExportProgressView = false
        }
    }
    
}
