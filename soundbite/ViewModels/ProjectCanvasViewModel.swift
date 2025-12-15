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

    func cleanup() {
        exportTask?.cancel()
        exportTask = nil

        audioPlayer.stop()
    }

    // TODO: Optimize export and clean up viewmodel/service relationship for better separation of concerns
    func performExport() {
        guard let audioURL = project.fileURL else {
            handleError(SoundbiteError.fileNotFound(project.songFilename))
            return
        }

        exportStartTime = startTime.distance(to: Date.now)

        stopPlayback()

        isExporting = true
        exportProgress = 0
        exportPhase = .rendering

        let projectSnapshot = project

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

    // TODO: Optimize export and clean up viewmodel/service relationship for better separation of concerns
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

        if fileManager.fileExists(atPath: videoOnlyURL.path()) {
            try fileManager.removeItem(at: videoOnlyURL)
        }
        if fileManager.fileExists(atPath: finalURL.path()) {
            try fileManager.removeItem(at: finalURL)
        }

        await onPhaseChange(.rendering, 0)
        Log.export.info("Rendering visuals...")
        try await manager.export(project: project, to: videoOnlyURL) { progress in
            onProgress(progress * 0.7) // Rendering is 70% of total
        }

        try Task.checkCancellation()

        await onPhaseChange(.merging, 0.7)
        Log.export.info("Merging audio...")
        try await manager.mergeAudio(videoURL: videoOnlyURL, audioURL: audioURL, outputURL: finalURL)

        try Task.checkCancellation()

        await onPhaseChange(.saving, 0.9)
        Log.export.info("Saving to library...")
        try await manager.saveToCameraRoll(fileURL: finalURL)

        await onPhaseChange(.saving, 1.0)

        try? fileManager.removeItem(at: videoOnlyURL)
        try? fileManager.removeItem(at: finalURL)

        Log.export.info("Export complete")
    }

    private func updateExportState(phase: ExportPhase, progress: Double) {
        exportPhase = phase
        exportProgress = progress
    }

    private func finishExport() async {
        isExporting = false
        exportTask = nil
        try? await Task.sleep(for: .milliseconds(100))
        startPlayback()
    }

    func cancelExport() {
        exportTask?.cancel()
        exportTask = nil
        isExporting = false

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
