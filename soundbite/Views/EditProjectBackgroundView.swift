//
//  EditProjectBackgroundView.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/3/25.
//

import SwiftUI

struct EditProjectBackgroundView: View {
    let project: Project
    
    var body: some View {
        VStack(spacing: 20) {
            Button("lines") {
                if project.background != .shader(SoundbiteShader.horizontalLinesInVoidReactive) {
                    project.background = .shader(SoundbiteShader.horizontalLinesInVoidReactive)
                }
            }
            Button("circles") {
                if project.background != .shader(SoundbiteShader.circlesInVoid) {
                    project.background = .shader(SoundbiteShader.circlesInVoid)
                }
            }
            Button("diamonds") {
                if project.background != .shader(SoundbiteShader.diamondsInVoid) {
                    project.background = .shader(SoundbiteShader.diamondsInVoid)
                }
            }
        }    }
}

