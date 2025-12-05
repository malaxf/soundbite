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
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ForEach(reactiveShaders, id: \.rawValue) { shader in
                    shaderSelectionButton(title: shader.rawValue, shader: shader)
                }
            }
            
            HStack {
                
            }
            
            HStack {
                
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
    
    func changePrimaryColorButton(color: Color) {
        Button {
            switch project.background {
            case .shader(let type, let primary, let secondary):
                // nothing
            case .image(let filename):
                // nothing
            case .color(let red, let green, let blue):
                // nothing
            }
        } label: {
            
        }
    }
}

