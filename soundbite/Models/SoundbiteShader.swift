//
//  SoundbiteShader.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/3/25.
//

import Foundation

nonisolated enum SoundbiteShader: String, Codable, CaseIterable, Sendable {
    // Void pack reactive
    case horizontalLinesInVoidReactive
    
    // Void pack non-reactive
    case diamondsInVoid
    case circlesInVoid
    
    var isReactive: Bool {
        self.rawValue.contains("Reactive")
    }
}
