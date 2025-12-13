//
//  ProjectService.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/28/25.
//

import Foundation
import SwiftData

@MainActor
final class ProjectService: ProjectRepository {
    private let modelContext: ModelContext
    private let fileService: FileManagementService

    init(modelContext: ModelContext, fileService: FileManagementService) {
        self.modelContext = modelContext
        self.fileService = fileService
    }

    func createProject(from audio: AudioRecording) throws -> Project {
        let newID = UUID()
        let newFilename = newID.uuidString + ".m4a"

        guard let sourceURL = audio.fileURL else {
            throw SoundbiteError.fileNotFound(audio.filename)
        }

        do {
            try fileService.cloneAudio(from: sourceURL, to: newFilename)

            let newProject = Project(songFilename: newFilename)
            newProject.id = newID

            modelContext.insert(newProject)
            try modelContext.save()

            Log.project.info("Project created successfully: \(newID.uuidString)")
            return newProject
        } catch let error as SoundbiteError {
            throw error
        } catch {
            throw SoundbiteError.projectCreationFailed(error.localizedDescription)
        }
    }

    func deleteProject(_ project: Project) throws {
        do {
            if let url = project.fileURL {
                try FileManager.default.removeItem(at: url)
            }

            modelContext.delete(project)
            try modelContext.save()

            Log.project.info("Project deleted: \(project.id.uuidString)")
        } catch {
            throw SoundbiteError.projectDeletionFailed(error.localizedDescription)
        }
    }
}
