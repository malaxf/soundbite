//
//  AudioExtractionManager.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/14/25.
//

import Foundation
import AVFoundation
import PhotosUI
import SwiftUI
import Observation

struct MovieFile: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return MovieFile(url: copy)
        }
    }
}

@Observable
class AudioExtractionManager {
    var isExtracting = false
    var errorMessage: String?
    
    var fileService = AudioFileService.shared
    
    // Processes a PhotosPickerItem and extracts audio. Returns audio data and title
    func processVideo(from item: PhotosPickerItem) async throws -> (filename: String, title: String) {
        isExtracting = true
        errorMessage = nil
        
        defer {
            isExtracting = false
        }
        
        guard let videoFile = try await item.loadTransferable(type: MovieFile.self) else {
            throw ExtractionError.failedToLoadVideo
        }
        
        let tempVideoURL = videoFile.url
        
        // Make sure file is less than 1gb so we don't crash
        let resources = try tempVideoURL.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resources.fileSize, fileSize > 1_000_000_000 {
            throw ExtractionError.fileTooLarge
        }
        
        defer {
            try? FileManager.default.removeItem(at: tempVideoURL)
        }
        
        // Convert to audio only file, save to disk, and return file name
        let filename = try await extractAudio(from: tempVideoURL)
        
        let title = generateTitle(from: tempVideoURL)
        
        return (filename, title)
    }
    
    // Extracts audio from a video URL and returns the location of the file
    private func extractAudio(from videoURL: URL) async throws -> String {
        let asset = AVURLAsset(url: videoURL)
        
        // Make sure asset has audio tracks
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        
        guard !tracks.isEmpty else {
            throw ExtractionError.noAudioTrack
        }
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ExtractionError.exportSessionFailed
        }
        
        // Configure export
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        // Export using modern API
        try await exportSession.export(to: outputURL, as: .m4a)
        
        defer {
            // Clean up file
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        let filename = try await fileService.moveAudio(from: outputURL)
        
        return filename
    }
    
    // Generates a default title from the video file name
    func generateTitle(from videoURL: URL) -> String {
        let fileName = videoURL.deletingPathExtension().lastPathComponent
        return fileName.isEmpty ? "Untitled Recording" : fileName
    }
    
    enum ExtractionError: LocalizedError {
        case failedToLoadVideo
        case noAudioTrack
        case exportSessionFailed
        case exportFailed(Error)
        case fileTooLarge
        
        var errorDescription: String? {
            switch self {
            case .failedToLoadVideo:
                return "Failed to load the selected video."
            case .noAudioTrack:
                return "The selected video does not contain an audio track."
            case .exportSessionFailed:
                return "Failed to create audio export session."
            case .exportFailed(let error):
                return "Failed to export audio: \(error.localizedDescription)"
            case .fileTooLarge:
                return "File was too big"
            }
        }
    }
}
