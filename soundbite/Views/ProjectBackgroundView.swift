//
//  ProjectBackgroundView.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/3/25.
//

import SwiftUI

struct ProjectBackgroundView: View {
    let background: ProjectBackground
    let time: TimeInterval
    let frequencyData: [Float]
    
    var body: some View {
        switch background {
        case .shader(let soundbiteShader):
            shaderView(for: soundbiteShader)
        case .image( _):
            Text("TODO: Implement image background")
        case .color(_, _, _):
            Text("TODO: Implement color background")
        }
    }
    
    @ViewBuilder
    func shaderView(for shader: SoundbiteShader) -> some View {
        Color.black.visualEffect { content, proxy in
            content.colorEffect(
                Shader(
                    function: ShaderLibrary[dynamicMember: shader.rawValue],
                    arguments: buildArguments(for: shader, proxy: proxy)
                )
            )
        }
    }
    
    nonisolated private func buildArguments(for shader: SoundbiteShader, proxy: GeometryProxy) -> [Shader.Argument] {
        return shader.isReactive ? [
            .float(time),
            .float2(proxy.size),
            .floatArray(frequencyData)
        ] : [
            .float(time),
            .float2(proxy.size)
        ]
    }
}


