//
//  Project.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/26/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    var id: UUID
    var name: String
    var createdAt: Date
    var songFilename: String
    var background: ProjectBackground

    init(
        name: String,
        songFilename: String,
        background: ProjectBackground = .shader(
            type: .horizontalLinesInVoidReactive,
            primary: ShaderColor.blue,
            secondary: ShaderColor.pink
        )
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.songFilename = songFilename
        self.background = background
    }

    @Transient
    var fileURL: URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentDirectory?.appendingPathComponent(songFilename)
    }
    
}
