//
//  EditProjectBackgroundView.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/3/25.
//

import SwiftUI

struct EditProjectBackgroundView: View {
    let project: Project
    
    var reactiveShaders: [SoundbiteShader] {
        SoundbiteShader.allCases.filter({ $0.isReactive })
    }
    
    let primaryColors: [CGColor] = [
        CGColor(red: 0, green: 0, blue: 1, alpha: 1),         // Blue (pairs with pink)
        CGColor(red: 0.8, green: 0, blue: 0, alpha: 1),       // Red (pairs with blue)
        CGColor(red: 0.8, green: 0, blue: 0, alpha: 1),       // Red (pairs with bright red)
        CGColor(red: 0.9, green: 0.7, blue: 0, alpha: 1),     // Gold (pairs with light yellow)
        CGColor(red: 0, green: 0.6, blue: 0.7, alpha: 1),     // Cyan (pairs with light cyan)
        CGColor(red: 0, green: 0, blue: 0, alpha: 1),         // Black (pairs with white)
        CGColor(red: 0, green: 0.6, blue: 0, alpha: 1),       // Green (pairs with lime)
        CGColor(red: 0.5, green: 0.4, blue: 0, alpha: 1),     // Olive (pairs with yellow)
        CGColor(red: 0.8, green: 0, blue: 0.2, alpha: 1),     // Deep pink (pairs with light pink)
    ]
    
    let secondaryColors: [CGColor] = [
        CGColor(red: 1, green: 0.6, blue: 1, alpha: 1),
        CGColor(red: 0.3, green: 0.3, blue: 1, alpha: 1),
        CGColor(red: 1, green: 0, blue: 0, alpha: 1),
        CGColor(red: 1, green: 1, blue: 0.6, alpha: 1),
        CGColor(red: 0.6, green: 1, blue: 1, alpha: 1),
        CGColor(red: 1, green: 1, blue: 1, alpha: 1),
        CGColor(red: 0.6, green: 1, blue: 0.3, alpha: 1),
        CGColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1),
        CGColor(red: 1, green: 0.5, blue: 0.5, alpha: 1),
    ]
    

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ForEach(reactiveShaders, id: \.rawValue) { shader in
                    shaderSelectionButton(title: shader.rawValue, shader: shader)
                }
            }
            
            if project.background.isShader {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary")
                            .font(.headline)
                            .padding(.horizontal, 16)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(primaryColors, id: \.self) { cgColor in
                                    primaryColorButton(color: cgColor)
                                }
                            }
                            .frame(height: 48)
                            .padding(.horizontal, 16)
                        }
                        .scrollIndicators(.hidden)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Secondary")
                            .font(.headline)
                            .padding(.horizontal, 16)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(secondaryColors, id: \.self) { cgColor in
                                    secondaryColorButton(color: cgColor)
                                }
                            }
                            .frame(height: 48)
                            .padding(.horizontal, 16)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
        }
    }
    
    
    func shaderSelectionButton(title: String, shader: SoundbiteShader) -> some View {
        Button(title) {
            if project.background.shaderType != shader {
                var newPrimary = ShaderColor.blue
                var newSecondary = ShaderColor.pink
                
                if case .shader(_, let currentPrimary, let currentSecondary) = project.background {
                    newPrimary = currentPrimary
                    newSecondary = currentSecondary
                }
                
                project.background = .shader(
                    type: shader,
                    primary: newPrimary,
                    secondary: newSecondary
                )
                
            }
        }
    }
    
    
    func primaryColorButton(color: CGColor) -> some View {
        Button {
            if case .shader(let shaderType, let currentPrimary, let secondary) = project.background {
                let newShaderColor = ShaderColor(color: color)
                if currentPrimary != newShaderColor {
                    project.background = .shader(
                        type: shaderType,
                        primary: ShaderColor(color: color),
                        secondary: secondary
                    )
                }
            }
        } label: {
            Circle()
                .fill(Color(cgColor: color))
                .overlay {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 5))
                        .foregroundStyle(
                            project.background.primaryShaderColor == ShaderColor(color: color) ?
                            Color.white.opacity(0.5) : Color.clear
                        )
                }
        }
    }
    
    func secondaryColorButton(color: CGColor) -> some View {
        Button {
            if case .shader(let shaderType, let primary, let currentSecondary) = project.background {
                let newShaderColor = ShaderColor(color: color)
                if currentSecondary != newShaderColor {
                    project.background = .shader(
                        type: shaderType,
                        primary: primary,
                        secondary: ShaderColor(color: color)
                    )
                }
            }
        } label: {
            Circle()
                .fill(Color(cgColor: color))
                .overlay {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 5))
                        .foregroundStyle(
                            project.background.secondaryShaderColor == ShaderColor(color: color) ?
                            Color.black.opacity(0.3) : Color.clear
                        )
                }
        }
    }
}

