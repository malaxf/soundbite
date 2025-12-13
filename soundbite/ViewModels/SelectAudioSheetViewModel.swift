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
class SelectAudioSheetViewModel {
    var selectedVideoItem: PhotosPickerItem?
    var showError = false
    var showDeleteAlert = false
    var showRenameAlert = false
    var tempName = ""
    var itemToEdit: AudioRecording?

    private(set) var audioImporter = AudioImportManager()

    var isExtracting: Bool {
        audioImporter.isExtracting
    }

    var errorMessage: String? {
        audioImporter.errorMessage
    }

    func handleVideoSelection(_ item: PhotosPickerItem?, modelContext: ModelContext) async {
        guard let item = item else { return }

        do {
            let (filename, title) = try await audioImporter.processVideo(from: item)

            let recording = AudioRecording(
                title: title,
                dateCreated: Date(),
                filename: filename
            )

            modelContext.insert(recording)
            try modelContext.save()

            selectedVideoItem = nil

        } catch {
            audioImporter.errorMessage = error.localizedDescription
            showError = true
        }
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
        try? modelContext.save()
        clearEditState()
    }

    func cancelDelete() {
        clearEditState()
    }

    func dismissError() {
        showError = false
    }
    
    private func clearEditState() {
        itemToEdit = nil
        tempName = ""
    }
}
