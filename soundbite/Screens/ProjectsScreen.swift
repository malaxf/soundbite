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
                if projects.isEmpty {
                    Spacer()
                    Text("Tap the + above to create a new project")
                        .foregroundStyle(Color.onContainer)
                    Spacer()
                } else {
                    projectsList
                    Spacer()
                }
            }
            .padding(16)
            .background(Color.background.ignoresSafeArea())
            .navigationTitle(Text("My Projects"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Project.self) { project in
                ProjectCanvasScreen(project: project)
            }
            .sheet(isPresented: $viewModel.showNewProjectSheet) {
                SelectAudioSheetView(onSelection: { recording in
                    viewModel.onAudioSelected(recording)
                })
                .presentationBackground(Color.background)
            }
            .sheet(isPresented: $viewModel.showNameProjectSheet, onDismiss: {
                viewModel.cancelProjectCreation()
            }) {
                if let recording = viewModel.selectedAudioRecording {
                    NameProjectView(songTitle: recording.title) { projectName in
                        viewModel.createProject(name: projectName, navigationManager: navigationManager)
                    }
                    .presentationBackground(Color.background)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("", systemImage: "plus") {
                        viewModel.showNewProjectSheet = true
                    }
                }
            }
        }
        .onAppear {
            viewModel.configure(with: context)
        }
    }

    private var projectsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(projects) { project in
                    Button {
                        navigationManager.navigateToEditor(for: project)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.title2)
                                    .foregroundStyle(Color.foreground)
                                Text(project.createdAt, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.onContainer)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.onContainer)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 96)
                        .frame(maxWidth: .infinity)
                        .background(Color.container)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
            }
        }
    }
}
