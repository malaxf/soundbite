//
//  ProjectsScreen.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/13/25.
//

import SwiftUI
import SwiftData

struct ProjectsScreen: View {
    @Environment(\.modelContext) var context
    @Query private var projects: [Project]
    @State private var viewModel = ProjectsViewModel()
    @State private var navigationManager = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            VStack {
                newProjectButton
                projectsList
                Spacer()
            }
            .padding(16)
            .background(Color.background.ignoresSafeArea())
            .navigationTitle(Text("Projects"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Project.self) { project in
                ProjectCanvasScreen(project: project)
            }
            .sheet(isPresented: $viewModel.showNewProjectSheet) {
                SelectAudioSheetView(onSelection: { recording in
                    viewModel.createProject(from: recording, navigationManager: navigationManager)
                })
                .presentationBackground(Color.background)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
        .onAppear {
            viewModel.configure(with: context)
        }
    }

    private var newProjectButton: some View {
        Button {
            viewModel.showNewProjectSheet = true
        } label: {
            HStack {
                Text("New Project")
                    .font(.title2)
                    .foregroundStyle(Color.foreground)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.container)
            .cornerRadius(24)
        }
    }

    private var projectsList: some View {
        VStack(spacing: 16) {
            ForEach(projects) { project in
                Button {
                    navigationManager.navigateToEditor(for: project)
                } label: {
                    Text(project.id.uuidString)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color.container)
                }
            }
        }
    }
}
