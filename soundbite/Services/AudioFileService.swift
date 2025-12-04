//
//  AudioFileService.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/20/25.
//

import Foundation

final class AudioFileService {
    static var shared = AudioFileService()
    
    private init() {}
    
    func saveAudio(data: Data) async throws -> String {
        let filename = UUID().uuidString + ".m4a"
        let url = URL.documentsDirectory.appending(path: filename)
        
        try data.write(to: url, options: .atomic)
        return filename
    }
    

    func moveAudio(from tempURL: URL) async throws -> String {
        print("TEMP: move audio called")
        let filename = UUID().uuidString + ".m4a"
        let destinationURL = URL.documentsDirectory.appending(path: filename)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        print("moveAudio basically done")
        return filename
    }
    
    func deleteAudio(filename: String) async {
        let url = URL.documentsDirectory.appending(path: filename)
        try? FileManager.default.removeItem(at: url)
    }
    
    func cloneAudio(from sourceURL: URL, to filename: String) throws {
        let destURL = URL.documentsDirectory.appending(path: filename)
        
        // Should not use extra disk space unless one of source or dest files are modified
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
    }
}
