//
//  Project.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/26/25.
//

import Foundation
import SwiftData
import SwiftUI


nonisolated enum ProjectBackground: Codable, Sendable, Equatable {
    case shader(SoundbiteShader)
    case image(filename: String)
    case color(red: Double, green: Double, blue: Double)
}

@Model
final class Project {
    var id: UUID
    var songFilename: String
    var background: ProjectBackground
    
    init(
        songFilename: String,
        background: ProjectBackground = .shader(.horizontalLinesInVoidReactive)
    ) {
        self.id = UUID()
        self.songFilename = songFilename
        self.background = background
    }

    @Transient
    var fileURL: URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentDirectory?.appendingPathComponent(songFilename)
    }
    
}
