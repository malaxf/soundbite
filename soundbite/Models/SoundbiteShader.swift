//
//  SoundbiteShader.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/3/25.
//

import Foundation
import SwiftUI


nonisolated enum ProjectBackground: Codable, Sendable, Equatable {
    case shader(type: SoundbiteShader, primary: ShaderColor, secondary: ShaderColor)
    case image(filename: String)
    case color(red: Double, green: Double, blue: Double)
    
    var shaderType: SoundbiteShader? {
        if case .shader(let type, _, _) = self {
            return type
        }
        return nil
    }
    
    var isShader: Bool {
        if case .shader(_, _, _) = self {
            return true
        } else {
            return false
        }
    }
}


nonisolated enum SoundbiteShader: String, Codable, CaseIterable, Sendable {
    // Void pack reactive
    case horizontalLinesInVoidReactive
    case circlesInVoidReactive
    case diamondsInVoidReactive
    
    // Void pack non-reactive
    case diamondsInVoid
    case circlesInVoid
    
    var isReactive: Bool {
        self.rawValue.contains("Reactive")
    }
}


nonisolated struct ShaderColor: Codable, Sendable, Equatable {
    var r: Double
    var g: Double
    var b: Double
    
    var swiftUIColor: Color {
        Color(red: r, green: g, blue: b)
    }
    
    var shaderComponents: [Float] {
        [Float(r), Float(g), Float(b), 1.0]
    }
    
    static let blue = ShaderColor(r: 0, g: 0, b: 1)
    static let pink = ShaderColor(r: 1, g: 0.6, b: 1)
}
