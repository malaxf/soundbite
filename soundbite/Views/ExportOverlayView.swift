//
//  ExportOverlayView.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/14/25.
//

import SwiftUI

struct ExportOverlayView: View {
    let progress: Double
    let phase: ExportPhase
    let onCancel: () -> Void

    private let spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    @State private var spinnerIndex = 0

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 120) {

                Spacer()
                Spacer()

                    HStack(spacing: 8) {

                        Text(spinnerFrames[spinnerIndex])
                            .foregroundStyle(Color.foreground)
                            .font(.title)
                            .monospaced()
                            .onAppear {
                                Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
                                    spinnerIndex = (spinnerIndex + 1) % spinnerFrames.count
                                }
                            }
                        
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phase.description)
                                .font(.title)
                                .foregroundStyle(Color.foreground)
                        }
                    }

                VStack(spacing: 16) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(Color.foreground)
                    HStack {
                        Text("This may take a moment.")
                            .foregroundStyle(Color.foreground)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(Color.foreground)
                    }
                }
                
                Spacer()

                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.body)
                            .frame(height: 60)
                            .padding(.horizontal, 16)
                            .foregroundStyle(Color.foreground)
                        
                    }
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ExportOverlayView(
        progress: 0.45,
        phase: .rendering,
        onCancel: {}
    )
}
