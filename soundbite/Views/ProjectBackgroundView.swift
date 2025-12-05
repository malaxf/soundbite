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
        case .shader(let soundbiteShader, let primary, let secondary):
            shaderView(for: soundbiteShader, primary, secondary)
        case .image( _):
            Text("TODO: Implement image background")
        case .color(_, _, _):
            Text("TODO: Implement color background")
        }
    }
    
    @ViewBuilder
    func shaderView(
        for shader: SoundbiteShader,
        _ primary: ShaderColor,
        _ secondary: ShaderColor
    ) -> some View {
        Color.black.visualEffect { content, proxy in
            content.colorEffect(
                Shader(
                    function: ShaderLibrary[dynamicMember: shader.rawValue],
                    arguments: buildArguments(for: shader, proxy: proxy, primary, secondary)
                )
            )
        }
    }
    
    nonisolated private func buildArguments(
        for shader: SoundbiteShader,
        proxy: GeometryProxy,
        _ primary: ShaderColor,
        _ secondary: ShaderColor
    ) -> [Shader.Argument] {
        return shader.isReactive ? [
            .float3(primary.r, primary.g, primary.b),
            .float3(secondary.r, secondary.g, secondary.b),
            .float(time),
            .float2(proxy.size),
            .floatArray(frequencyData)
        ] : [
            .float3(primary.r, primary.g, primary.b),
            .float(time),
            .float2(proxy.size)
        ]
    }
}


