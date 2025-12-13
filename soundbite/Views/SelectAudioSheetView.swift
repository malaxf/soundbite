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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var audioRecordings: [AudioRecording]

    @State private var viewModel = SelectAudioSheetViewModel()
    
    var onSelection: (_: AudioRecording) -> ()

    var body: some View {
        VStack(spacing: 24) {
            Text("Select Song")
                .font(.title2)
                .foregroundStyle(Color.foreground)

            if viewModel.isExtracting {
                ProgressView("Extracting audio...")
                    .foregroundStyle(Color.foreground)
            }

            PhotosPicker(selection: $viewModel.selectedVideoItem, matching: .videos, preferredItemEncoding: .current) {
                Text("Add Song from Video")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.container)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .foregroundStyle(Color.foreground)
            }
            .disabled(viewModel.isExtracting)

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
        .onChange(of: viewModel.selectedVideoItem) { oldValue, newValue in
            Task {
                await viewModel.handleVideoSelection(newValue, modelContext: modelContext)
            }
        }
        .alert("Rename Song", isPresented: $viewModel.showRenameAlert) {
            TextField("New Name", text: $viewModel.tempName)
            Button("Save") {
                viewModel.confirmRename()
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelRename()
            }
        }
        .alert("Delete Song?", isPresented: $viewModel.showDeleteAlert) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    viewModel.confirmDelete(modelContext: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
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
                                viewModel.startRename(for: recording)
                            } label: {
                                Text("Edit title")
                                Image(systemName: "pencil")
                            }
                            Button(role: .destructive) {
                                viewModel.startDelete(for: recording)
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
}

#Preview {
    SelectAudioSheetView { _ in

    }
}
