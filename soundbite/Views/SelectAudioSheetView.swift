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
    
    @State private var showDeleteAlert = false
    @State private var showRenameAlert = false
    @State private var tempName = ""
    @State private var itemToEdit: AudioRecording? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Song")
                .font(.title2)
                .foregroundStyle(Color.foreground)
            
            if extractor.isExtracting {
                ProgressView("Extracting audio...")
                    .foregroundStyle(Color.foreground)
            }
            
            PhotosPicker(selection: $selectedVideoItem, matching: .videos, preferredItemEncoding: .current) {
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
                audioReordingsList
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
        .alert("Rename Song", isPresented: $showRenameAlert) {
            TextField("New Name", text: $tempName)
            Button("Save") {
                guard let item = itemToEdit else {
                    return
                }
                item.title = tempName
                itemToEdit = nil
                tempName = ""
            }
            Button("Cancel", role: .cancel) {
                itemToEdit = nil
                tempName = ""
            }
        }
        .alert("Delete Song?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                guard let item = itemToEdit else {
                    return
                }
                
                withAnimation {
                    modelContext.delete(item)
                    itemToEdit = nil
                }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {
                itemToEdit = nil
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
    
    private var audioReordingsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(audioRecordings) { recording in
                    HStack {
                        Button {
                            onSelection(recording)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(recording.title)
                                    .font(.headline)
                                Text(recording.dateCreated, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        
                        Menu {
                            Button {
                                itemToEdit = recording
                                showRenameAlert = true
                            } label: {
                                Text("Edit title")
                                Image(systemName: "pencil")
                            }
                            Button(role: .destructive) {
                                itemToEdit = recording
                                showDeleteAlert = true
                            } label: {
                                Text("Delete song")
                                Image(systemName: "trash")
                            }
                            
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.foreground)
                                .frame(width: 48, height: 48)
                                .background {
                                    Color.container.mix(with: Color.white, by: 0.2)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                                .frame(width: 56, height: 56)
                            
                        }
                    }
                    .foregroundStyle(Color.foreground)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.container)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    
                }
            }
        }
    }
    
    private func handleVideoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            // Process video and extract audio
            let (filename, title) = try await extractor.processVideo(from: item)
            
            // MARK: instead of sacing the recordign immediately, we can have the user name the recordign while the extractor is processing the video
            
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
