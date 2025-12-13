//
//  AudioImportManager.swift
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

@MainActor @Observable
class AudioImportManager {
    var isExtracting = false
    var errorMessage: String?

    private let fileService: FileManagementService

    init(fileService: FileManagementService = AudioFileService()) {
        self.fileService = fileService
    }

    func processVideo(from item: PhotosPickerItem) async throws -> (filename: String, title: String) {
        Log.audio.info("Starting video extraction")
        isExtracting = true
        errorMessage = nil

        defer { isExtracting = false }

        guard let videoFile = try await item.loadTransferable(type: MovieFile.self) else {
            throw SoundbiteError.audioExtractionFailed("Failed to load video")
        }

        let tempVideoURL = videoFile.url

        let resources = try tempVideoURL.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resources.fileSize, fileSize > 1_000_000_000 {
            throw SoundbiteError.fileTooLarge(fileSize / 1_000_000)
        }

        defer { try? FileManager.default.removeItem(at: tempVideoURL) }

        let filename = try await extractAudio(from: tempVideoURL)
        let title = generateTitle(from: tempVideoURL)

        Log.audio.info("Extraction complete: \(title)")
        return (filename, title)
    }

    private func extractAudio(from videoURL: URL) async throws -> String {
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()

        guard let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first,
              let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw SoundbiteError.noAudioTrack
        }

        let duration = try await asset.load(.duration)
        try compositionTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: sourceAudioTrack, at: .zero
        )

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            throw SoundbiteError.audioExtractionFailed("Failed to create export session")
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        try await exportSession.export(to: outputURL, as: .m4a)

        defer { try? FileManager.default.removeItem(at: outputURL) }

        let filename = try await fileService.moveAudio(from: outputURL)
        return filename
    }

    func generateTitle(from videoURL: URL) -> String {
        let fileName = videoURL.deletingPathExtension().lastPathComponent
        return fileName.isEmpty ? "Untitled Recording" : fileName
    }
}
