//
//  ProjectCanvasViewModel.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/13/25.
//

import Foundation
import SwiftUI
import Observation

enum ExportPhase: String {
    case rendering = "Rendering video..."
    case merging = "Merging audio..."
    case saving = "Saving to library..."

    var description: String { rawValue }
}

@MainActor @Observable
final class ProjectCanvasViewModel {
    var showChangeBackgroundSheet = false
    var isExporting = false
    var exportProgress: Double = 0
    var exportPhase: ExportPhase = .rendering
    var exportStartTime: TimeInterval = 0
    var errorMessage: String?
    var showError = false

    private(set) var audioPlayer = AudioPlayerManager()
    private var exportTask: Task<Void, Never>?

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

    /// Clean up resources when the view disappears
    func cleanup() {
        // Cancel any in-progress export
        exportTask?.cancel()
        exportTask = nil

        // Stop audio playback and release resources
        audioPlayer.stop()
    }

    func performExport() {
        guard let audioURL = project.fileURL else {
            handleError(SoundbiteError.fileNotFound(project.songFilename))
            return
        }

        // Store current animation time before pausing
        exportStartTime = startTime.distance(to: Date.now)

        // Stop playback during export
        stopPlayback()

        isExporting = true
        exportProgress = 0
        exportPhase = .rendering

        // Capture values needed for export before entering async context
        let projectSnapshot = project

        // Create @Sendable closures BEFORE Task.detached to properly capture [weak self]
        // Swift 6 doesn't allow capturing `var` in concurrent code, so we create these closures
        // on the MainActor where [weak self] capture is valid
        let onPhaseChange: @Sendable (ExportPhase, Double) async -> Void = { [weak self] phase, progress in
            await self?.updateExportState(phase: phase, progress: progress)
        }
        let onProgress: @Sendable (Double) -> Void = { [weak self] progress in
            let strongSelf = self
            Task { @MainActor in
                strongSelf?.exportProgress = progress
            }
        }
        let onFinish: @Sendable () async -> Void = { [weak self] in
            await self?.finishExport()
        }
        let onError: @Sendable (Error) async -> Void = { [weak self] error in
            await self?.handleError(SoundbiteError.exportFailed(error.localizedDescription))
        }

        // Use Task.detached to ensure work runs off the MainActor executor
        exportTask = Task.detached(priority: .userInitiated) {
            do {
                try await Self.runExport(
                    project: projectSnapshot,
                    audioURL: audioURL,
                    onPhaseChange: onPhaseChange,
                    onProgress: onProgress
                )
                await onFinish()
            } catch is CancellationError {
                Log.export.info("Export cancelled")
            } catch {
                await onError(error)
                await onFinish()
            }
        }
    }

    /// Runs the export pipeline completely detached from MainActor.
    /// This is a static function to ensure no accidental MainActor-isolated property access.
    private static func runExport(
        project: Project,
        audioURL: URL,
        onPhaseChange: @escaping @Sendable (ExportPhase, Double) async -> Void,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let manager = ProjectExportManager()
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let videoOnlyURL = tempDir.appendingPathComponent("temp_video.mp4")
        let finalURL = tempDir.appendingPathComponent("soundbite_export_\(Date().timeIntervalSince1970).mp4")

        // Clean up any existing temp files
        if fileManager.fileExists(atPath: videoOnlyURL.path()) {
            try fileManager.removeItem(at: videoOnlyURL)
        }
        if fileManager.fileExists(atPath: finalURL.path()) {
            try fileManager.removeItem(at: finalURL)
        }

        // Phase 1: Render video
        await onPhaseChange(.rendering, 0)
        Log.export.info("Rendering visuals...")
        try await manager.export(project: project, to: videoOnlyURL) { progress in
            onProgress(progress * 0.7) // Rendering is 70% of total
        }

        try Task.checkCancellation()

        // Phase 2: Merge audio
        await onPhaseChange(.merging, 0.7)
        Log.export.info("Merging audio...")
        try await manager.mergeAudio(videoURL: videoOnlyURL, audioURL: audioURL, outputURL: finalURL)

        try Task.checkCancellation()

        // Phase 3: Save to library
        await onPhaseChange(.saving, 0.9)
        Log.export.info("Saving to library...")
        try await manager.saveToCameraRoll(fileURL: finalURL)

        await onPhaseChange(.saving, 1.0)

        // Cleanup temp files
        try? fileManager.removeItem(at: videoOnlyURL)
        try? fileManager.removeItem(at: finalURL)

        Log.export.info("Export complete")
    }

    /// Updates export state on the main actor.
    private func updateExportState(phase: ExportPhase, progress: Double) {
        exportPhase = phase
        exportProgress = progress
    }

    private func finishExport() async {
        isExporting = false
        exportTask = nil
        // Small delay before resuming audio to ensure clean state
        try? await Task.sleep(for: .milliseconds(100))
        startPlayback()
    }

    func cancelExport() {
        // Cancel the task first
        exportTask?.cancel()
        exportTask = nil

        // Then update state on main actor
        isExporting = false

        // Delay playback restart to avoid audio glitches
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            self?.startPlayback()
        }
    }

    private func handleError(_ error: Error) {
        Log.audio.error(error)
        errorMessage = error.localizedDescription
        showError = true
    }
}
