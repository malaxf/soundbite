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
    
    @State private var showNewProjectSheet = false
    @State private var navigationManager = NavigationManager()
    
    @Query private var projects: [Project]
    
    private var service: ProjectService {
        ProjectService(modelContext: context)
    }
    
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
            .sheet(isPresented: $showNewProjectSheet) {
                SelectAudioSheetView(onSelection: { recording in
                    
                    guard let newProject = service.createNewProject(from: recording) else {
                        showNewProjectSheet = false
                        return
                    }
                    
                    showNewProjectSheet = false
                    navigationManager.navigateToEditor(for: newProject)
                })
                .presentationBackground(Color.background)
            }
        }
        .onAppear {
            for project in projects {
                print(project.songFilename)
            }
            if projects.isEmpty {
                print("projects are empty")
            }
        }
        .onChange(of: projects) { _,_ in
            for project in projects {
                print(project.songFilename)
            }
        }
        
    }
    
    private var newProjectButton: some View {
        Button {
            showNewProjectSheet = true
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

//#Preview {
//    ProjectsScreen()
//        .preferredColorScheme(.dark)
//}
