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
    
    var primaryShaderColor: ShaderColor? {
        if case .shader(_, let primary, _) = self {
            return primary
        }
        return nil
    }
    
    var secondaryShaderColor: ShaderColor? {
        if case .shader(_, _, let secondary) = self {
            return secondary        }
        return nil
    }
}


enum ShaderPack: String, CaseIterable {
    case void = "Void"
    case phosphor = "Phosphor"
}

nonisolated enum SoundbiteShader: String, Codable, CaseIterable, Sendable {
    // Void pack reactive
    case horizontalLinesInVoidReactive
    case circlesInVoidReactive
    case diamondsInVoidReactive

    // Void pack non-reactive
    case diamondsInVoid
    case circlesInVoid

    // Phosphor pack
    case phosphorTunnelReactive
    case phosphorFabricReactive

    var isReactive: Bool {
        self.rawValue.contains("Reactive")
    }

    var pack: ShaderPack {
        switch self {
        case .horizontalLinesInVoidReactive, .circlesInVoidReactive, .diamondsInVoidReactive,
             .diamondsInVoid, .circlesInVoid:
            return .void
        case .phosphorTunnelReactive, .phosphorFabricReactive:
            return .phosphor
        }
    }

    var displayName: String {
        switch self {
        case .horizontalLinesInVoidReactive: return "Lines"
        case .circlesInVoidReactive: return "Circles"
        case .diamondsInVoidReactive: return "Diamonds"
        case .diamondsInVoid: return "Diamonds"
        case .circlesInVoid: return "Circles"
        case .phosphorTunnelReactive: return "Tunnel"
        case .phosphorFabricReactive: return "Fabric"
        }
    }

    var iconName: String {
        switch self {
        case .horizontalLinesInVoidReactive: return "line.3.horizontal"
        case .circlesInVoidReactive: return "circle.grid.2x2"
        case .diamondsInVoidReactive: return "diamond"
        case .diamondsInVoid: return "diamond"
        case .circlesInVoid: return "circle.grid.2x2"
        case .phosphorTunnelReactive: return "circle.dotted"
        case .phosphorFabricReactive: return "square.grid.3x3"
        }
    }
}


nonisolated struct ShaderColor: Codable, Sendable, Equatable {
    var r: Double
    var g: Double
    var b: Double
    
    var swiftUIColor: Color {
        Color(red: r, green: g, blue: b)
    }
    
    var cgColor: CGColor {
        CGColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    var shaderComponents: [Float] {
        [Float(r), Float(g), Float(b), 1.0]
    }
    
    static let blue = ShaderColor(r: 0, g: 0, b: 1)
    static let pink = ShaderColor(r: 1, g: 0.6, b: 1)
    
    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    init(color: CGColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        let components = color.components
        
        r = components?[0] ?? 0
        g = components?[1] ?? 0
        b = components?[2] ?? 0
        
        self.r = r
        self.g = g
        self.b = b
    }
}
