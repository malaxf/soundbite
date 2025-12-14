//
//  SelectAudioSheetViewModel.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/9/25.
//

import Foundation
import Observation
import SwiftData
import _PhotosUI_SwiftUI

@MainActor @Observable
final class SelectAudioSheetViewModel {
    var selectedVideoItem: PhotosPickerItem?
    var showError = false
    var showDeleteAlert = false
    var showRenameAlert = false
    var showNameNewSongAlert = false
    var tempName = ""
    var itemToEdit: AudioRecording?
    var errorMessage: String?

    var pendingFilename: String?
    var pendingSuggestedTitle: String?

    private let audioImporter = AudioImportManager()

    var isExtracting: Bool {
        audioImporter.isExtracting
    }

    func handleVideoSelection(_ item: PhotosPickerItem?, modelContext: ModelContext) async {
        guard let item = item else { return }

        do {
            let (filename, title) = try await audioImporter.processVideo(from: item)

            pendingFilename = filename
            pendingSuggestedTitle = title
            tempName = title
            showNameNewSongAlert = true

            selectedVideoItem = nil
        } catch {
            Log.audio.error(error)
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func confirmNewSongName(modelContext: ModelContext) {
        guard let filename = pendingFilename else { return }

        let finalTitle = tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (pendingSuggestedTitle ?? "Untitled Recording")
            : tempName.trimmingCharacters(in: .whitespacesAndNewlines)

        let recording = AudioRecording(
            title: finalTitle,
            dateCreated: Date(),
            filename: filename
        )

        modelContext.insert(recording)
        do {
            try modelContext.save()
        } catch {
            Log.audio.error(error)
            errorMessage = error.localizedDescription
            showError = true
        }

        clearPendingSong()
    }

    func cancelNewSong() {
        if let filename = pendingFilename {
            Task {
                await AudioFileService().deleteAudio(filename: filename)
            }
        }
        clearPendingSong()
    }

    private func clearPendingSong() {
        pendingFilename = nil
        pendingSuggestedTitle = nil
        tempName = ""
    }

    func startRename(for recording: AudioRecording) {
        itemToEdit = recording
        tempName = recording.title
        showRenameAlert = true
    }

    func confirmRename() {
        guard let item = itemToEdit else { return }
        item.title = tempName
        clearEditState()
    }

    func cancelRename() {
        clearEditState()
    }

    func startDelete(for recording: AudioRecording) {
        itemToEdit = recording
        showDeleteAlert = true
    }

    func confirmDelete(modelContext: ModelContext) {
        guard let item = itemToEdit else { return }
        modelContext.delete(item)
        do {
            try modelContext.save()
        } catch {
            Log.project.error(error, context: "Failed to delete recording")
        }
        clearEditState()
    }

    func cancelDelete() {
        clearEditState()
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }

    private func clearEditState() {
        itemToEdit = nil
        tempName = ""
    }
}
