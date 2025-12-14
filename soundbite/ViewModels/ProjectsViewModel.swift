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
    var showNameProjectSheet = false
    var errorMessage: String?
    var showError = false

    var selectedAudioRecording: AudioRecording?

    private var repository: ProjectRepository?

    func configure(with context: ModelContext) {
        self.repository = ProjectService(modelContext: context, fileService: AudioFileService())
    }

    func onAudioSelected(_ audio: AudioRecording) {
        selectedAudioRecording = audio
        showNewProjectSheet = false
        showNameProjectSheet = true
    }

    func createProject(name: String, navigationManager: NavigationManager) {
        guard let repository, let audio = selectedAudioRecording else { return }

        do {
            let project = try repository.createProject(name: name, from: audio)
            showNameProjectSheet = false
            selectedAudioRecording = nil
            navigationManager.navigateToEditor(for: project)
        } catch {
            handleError(error)
            showNameProjectSheet = false
            selectedAudioRecording = nil
        }
    }

    func cancelProjectCreation() {
        showNameProjectSheet = false
        selectedAudioRecording = nil
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
