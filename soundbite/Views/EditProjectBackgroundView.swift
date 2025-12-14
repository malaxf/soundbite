//
//  EditProjectBackgroundView.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/3/25.
//

import SwiftUI

struct EditProjectBackgroundView: View {
    let project: Project
    
    var voidShaders: [SoundbiteShader] {
        SoundbiteShader.allCases.filter { $0.isReactive && $0.pack == .void }
    }

    var phosphorShaders: [SoundbiteShader] {
        SoundbiteShader.allCases.filter { $0.isReactive && $0.pack == .phosphor }
    }
    
    let primaryColors: [CGColor] = [
        CGColor(red: 0, green: 0, blue: 1, alpha: 1),
        CGColor(red: 0.8, green: 0, blue: 0, alpha: 1),
        CGColor(red: 0.5, green: 0, blue: 0, alpha: 1),
        CGColor(red: 0.1, green: 0.1, blue: 0, alpha: 1),
        CGColor(red: 0, green: 0.6, blue: 0.7, alpha: 1),
        CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        CGColor(red: 0, green: 0.6, blue: 0, alpha: 1),
        CGColor(red: 0.2, green: 0.2, blue: 1, alpha: 1),
        CGColor(red: 0.8, green: 0, blue: 0.2, alpha: 1),
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
        CGColor(red: 0, green: 0, blue: 1, alpha: 1),
    ]
    

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shader")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal) {
                    HStack(spacing: 20) {
                        shaderPackSection(title: "Void", shaders: voidShaders)
                        shaderPackSection(title: "Phosphor", shaders: phosphorShaders)
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
            }

            if project.background.isShader {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary")
                            .font(.headline)
                            .padding(.horizontal, 16)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
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
                            HStack(spacing: 8) {
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
    
    
    func shaderPackSection(title: String, shaders: [SoundbiteShader]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.foreground.opacity(0.8))
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(shaders, id: \.rawValue) { shader in
                    shaderSelectionButton(shader: shader)
                }
            }
        }
    }

    func shaderSelectionButton(shader: SoundbiteShader) -> some View {
        let isSelected = project.background.shaderType == shader

        return Button {
            if !isSelected {
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
        } label: {
            VStack(spacing: 8) {
                Image(systemName: shader.iconName)
                    .font(.title2)
                Text(shader.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 72, height: 72)
            .foregroundStyle(isSelected ? Color.white : Color.foreground)
            .background(isSelected ? Color.accentColor : Color.container)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 2)
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
                        .strokeBorder(style: StrokeStyle(lineWidth: 4))
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
                        .strokeBorder(style: StrokeStyle(lineWidth: 4))
                        .foregroundStyle(
                            project.background.secondaryShaderColor == ShaderColor(color: color) ?
                            Color.black.opacity(0.3) : Color.clear
                        )
                }
        }
    }
}

