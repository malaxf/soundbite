//
//  AudioFileService.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/20/25.
//

import Foundation

final class AudioFileService: FileManagementService, Sendable {
    nonisolated init() {}

    func saveAudio(data: Data) async throws -> String {
        let filename = UUID().uuidString + ".m4a"
        let url = URL.documentsDirectory.appending(path: filename)

        try data.write(to: url, options: .atomic)
        Log.fileService.info("Audio saved: \(filename)")
        return filename
    }

    func moveAudio(from tempURL: URL) async throws -> String {
        let filename = UUID().uuidString + ".m4a"
        let destinationURL = URL.documentsDirectory.appending(path: filename)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        Log.fileService.info("Audio moved to: \(filename)")
        return filename
    }

    func deleteAudio(filename: String) async {
        let url = URL.documentsDirectory.appending(path: filename)
        try? FileManager.default.removeItem(at: url)
        Log.fileService.info("Audio deleted: \(filename)")
    }

    func cloneAudio(from sourceURL: URL, to filename: String) throws {
        let destURL = URL.documentsDirectory.appending(path: filename)
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        Log.fileService.info("Audio cloned to: \(filename)")
    }
}
