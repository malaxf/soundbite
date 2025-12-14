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
        TimelineView(.animation(paused: viewModel.isExporting)) { tl in
            let time = viewModel.isExporting
                ? viewModel.exportStartTime
                : viewModel.startTime.distance(to: tl.date)

            ProjectBackgroundView(
                background: viewModel.project.background,
                time: time,
                frequencyData: viewModel.frequencyData
            )
        }
        .ignoresSafeArea()
        .backgroundStyle(Color.background)
        .onAppear {
            viewModel.startPlayback()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("", systemImage: "arrow.down.to.line", role: .none) {
                    viewModel.performExport()
                }
                .disabled(viewModel.isExporting)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("", systemImage: "paintbrush", role: .none) {
                    viewModel.showChangeBackgroundSheet = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showChangeBackgroundSheet) {
            EditProjectBackgroundView(project: viewModel.project)
                .presentationDetents([.height(356)])
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .fullScreenCover(isPresented: $viewModel.isExporting) {
            ExportOverlayView(
                progress: viewModel.exportProgress,
                phase: viewModel.exportPhase,
                onCancel: { viewModel.cancelExport() }
            )
        }
    }
}
