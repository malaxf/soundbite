//
//  AudioRecording.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/13/25.
//

import Foundation
import SwiftData

@Model
final class AudioRecording {
    var id: UUID
    var title: String
    var dateCreated: Date // TODO: change property name to createdAt to match Project
    var filename: String
    
    init(id: UUID = UUID(), title: String, dateCreated: Date, filename: String) {
        self.id = id
        self.title = title
        self.dateCreated = dateCreated
        self.filename = filename
    }
    
    @Transient
    var fileURL: URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentDirectory?.appendingPathComponent(filename)
    }
}
