//
//  SelectAudioSheetView.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/13/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct SelectAudioSheetView: View {
    var onSelection: (_: AudioRecording) -> ()
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var audioRecordings: [AudioRecording]
    
    @State private var showVideoPicker = false
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var extractor = AudioExtractionManager()
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Song")
                .font(.title2)
                .foregroundStyle(Color.foreground)
            
            if extractor.isExtracting {
                ProgressView("Extracting audio...")
                    .foregroundStyle(Color.foreground)
            }
            
            PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                Text("Add Song from Video")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.container)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .foregroundStyle(Color.foreground)
            }
            .disabled(extractor.isExtracting)
            
            // List of existing audio recordings
            if !audioRecordings.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(audioRecordings) { recording in
                            Button {
                                onSelection(recording)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(recording.title)
                                            .font(.headline)
                                        Text(recording.dateCreated, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "music.note")
                                }
                                .foregroundStyle(Color.foreground)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.container)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            } else {
                Text("No audio recordings yet")
                    .foregroundStyle(.secondary)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: selectedVideoItem) { oldValue, newValue in
            Task {
                await handleVideoSelection(newValue)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = extractor.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func handleVideoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            // Process video and extract audio
            let (filename, title) = try await extractor.processVideo(from: item)
            
            // Create and save AudioRecording
            let recording = AudioRecording(
                title: title,
                dateCreated: Date(),
                filename: filename
            )
            
            modelContext.insert(recording)
            try modelContext.save()
            
            // Reset picker
            selectedVideoItem = nil
            
        } catch {
            extractor.errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    SelectAudioSheetView { _ in
        
    }
}
