//
//  ProjectCanvasScreen.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/15/25.
//

import SwiftUI
import MetalKit

struct ProjectCanvasScreen: View {
    @State private var viewModel: ProjectCanvasViewModel

    init(project: Project) {
        _viewModel = State(initialValue: ProjectCanvasViewModel(project: project))
    }

    var body: some View {
        ZStack {
            TimelineView(.animation) { tl in
                let time = viewModel.startTime.distance(to: tl.date)

                ProjectBackgroundView(
                    background: viewModel.project.background,
                    time: time,
                    frequencyData: viewModel.frequencyData
                )
            }
            .ignoresSafeArea()

            if viewModel.isExporting {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 20) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                    Text("Rendering & Exporting...")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .backgroundStyle(Color.background)
        .onAppear {
            viewModel.startPlayback()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "arrow.down.to.line", role: .none) {
                    Task {
                        await viewModel.performExport()
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("", systemImage: "paintbrush", role: .none) {
                    viewModel.showChangeBackgroundSheet = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showChangeBackgroundSheet) {
            EditProjectBackgroundView(project: viewModel.project)
                .presentationDetents([.medium])
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}
