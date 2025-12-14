//
//  ServiceProtocols.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/13/25.
//

import Foundation
import SwiftData

protocol FileManagementService: Sendable {
    func saveAudio(data: Data) async throws -> String
    func moveAudio(from tempURL: URL) async throws -> String
    func deleteAudio(filename: String) async
    func cloneAudio(from sourceURL: URL, to filename: String) throws
}

@MainActor
protocol ProjectRepository {
    func createProject(name: String, from audio: AudioRecording) throws -> Project
    func deleteProject(_ project: Project) throws
}
