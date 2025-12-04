//
//  ProjectsManager.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/28/25.
//

import Foundation
import SwiftData

class ProjectService {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createNewProject(from audio: AudioRecording) -> Project? {
        let newID = UUID()
        let newFilename = newID.uuidString + ".m4a"
        
        guard let sourceURL = audio.fileURL else { return nil }
        
        do {
            try AudioFileService.shared.cloneAudio(from: sourceURL, to: newFilename)
            
            let newProject = Project(songFilename: newFilename)
            newProject.id = newID
            
            modelContext.insert(newProject)
            
            try modelContext.save()
            
            print("[ProjectService]: Project created sucessfully")
            
            return newProject
            
        } catch {
            print("ERROR: Could not create project: \(error)")
            return nil
        }
    }
    
    func deleteProject(_ project: Project) {
        if let url = project.fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        modelContext.delete(project)
        try? modelContext.save()
    }
}
