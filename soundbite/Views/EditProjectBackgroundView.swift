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
    
    let colors = [
        UIColor(red: 0, green: 0, blue: 1, alpha: 1),
        UIColor(red: 1, green: 0, blue: 0, alpha: 1),
        UIColor(red: 0, green: 1, blue: 0, alpha: 1),
        UIColor(red: 1, green: 0.6, blue: 1, alpha: 1),
        UIColor(red: 0.6, green: 1, blue: 1, alpha: 1),
        UIColor(red: 1, green: 1, blue: 0.6, alpha: 1)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ForEach(reactiveShaders, id: \.rawValue) { shader in
                    shaderSelectionButton(title: shader.rawValue, shader: shader)
                }
            }
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(colors, id: \.self) { color in
                        changePrimaryColorButton(color: color)
                    }
                }
            }
            .frame(height: 40)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(colors, id: \.self) { color in
                        changeSecondaryColorButton(color: color)
                    }
                }
            }
            .frame(height: 40)
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
    
    func changePrimaryColorButton(color: UIColor) -> some View {
        Button {
            if case .shader(let type, _, let secondary) = project.background {
                project.background = .shader(
                    type: type,
                    primary: ShaderColor(color: color),
                    secondary: secondary
                )
            }
        } label: {
            Circle()
                .fill(Color(uiColor: color))
        }
    }
    
    func changeSecondaryColorButton(color: UIColor) -> some View {
        Button {
            if case .shader(let type, let primary, _) = project.background {
                project.background = .shader(
                    type: type,
                    primary: primary,
                    secondary: ShaderColor(color: color)
                )
            }
        } label: {
            Circle()
                .fill(Color(uiColor: color))
        }
    }
}

