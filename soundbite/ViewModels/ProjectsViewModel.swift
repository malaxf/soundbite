//
//  ProjectsViewModel.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/13/25.
//

import Foundation
import SwiftUI
import SwiftData
import Observation

@MainActor @Observable
final class ProjectsViewModel {
    var showNewProjectSheet = false
    var errorMessage: String?
    var showError = false

    private var repository: ProjectRepository?

    func configure(with context: ModelContext) {
        self.repository = ProjectService(modelContext: context, fileService: AudioFileService())
    }

    func createProject(from audio: AudioRecording, navigationManager: NavigationManager) {
        guard let repository else { return }

        do {
            let project = try repository.createProject(from: audio)
            showNewProjectSheet = false
            navigationManager.navigateToEditor(for: project)
        } catch {
            handleError(error)
            showNewProjectSheet = false
        }
    }

    func deleteProject(_ project: Project) {
        guard let repository else { return }

        do {
            try repository.deleteProject(project)
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        Log.project.error(error)
        errorMessage = error.localizedDescription
        showError = true
    }
}
