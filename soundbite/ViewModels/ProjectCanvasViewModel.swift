//
//  ProjectCanvasViewModel.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/13/25.
//

import Foundation
import SwiftUI
import Observation

@MainActor @Observable
final class ProjectCanvasViewModel {
    var showChangeBackgroundSheet = false
    var isExporting = false
    var errorMessage: String?
    var showError = false

    private(set) var audioPlayer = AudioPlayerManager()
    let project: Project
    let startTime = Date.now

    init(project: Project) {
        self.project = project
    }

    var frequencyData: [Float] {
        Array(audioPlayer.frequencyData.reversed())
    }

    func startPlayback() {
        guard let url = project.fileURL else {
            handleError(SoundbiteError.fileNotFound(project.songFilename))
            return
        }

        do {
            try audioPlayer.play(url: url)
        } catch {
            handleError(error)
        }
    }

    func stopPlayback() {
        audioPlayer.stop()
    }

    func performExport() async {
        guard let audioURL = project.fileURL else {
            handleError(SoundbiteError.fileNotFound(project.songFilename))
            return
        }

        isExporting = true
        defer { isExporting = false }

        do {
            let manager = ProjectExportManager()
            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            let videoOnlyURL = tempDir.appendingPathComponent("temp_video.mp4")
            let finalURL = tempDir.appendingPathComponent("soundbite_export_\(Date().timeIntervalSince1970).mp4")

            if fileManager.fileExists(atPath: videoOnlyURL.path()) {
                try fileManager.removeItem(at: videoOnlyURL)
            }
            if fileManager.fileExists(atPath: finalURL.path()) {
                try fileManager.removeItem(at: finalURL)
            }

            Log.export.info("Rendering visuals...")
            try await manager.export(project: project, to: videoOnlyURL)

            Log.export.info("Merging audio...")
            try await manager.mergeAudio(videoURL: videoOnlyURL, audioURL: audioURL, outputURL: finalURL)

            Log.export.info("Saving to library...")
            try await manager.saveToCameraRoll(fileURL: finalURL)

            try? fileManager.removeItem(at: videoOnlyURL)
            try? fileManager.removeItem(at: finalURL)

            Log.export.info("Export complete")
        } catch {
            handleError(SoundbiteError.exportFailed(error.localizedDescription))
        }
    }

    private func handleError(_ error: Error) {
        Log.audio.error(error)
        errorMessage = error.localizedDescription
        showError = true
    }
}
