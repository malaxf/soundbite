//
//  ProjectsScreen.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/13/25.
//

import SwiftUI

struct ProjectsScreen: View {
    
    @State private var showNewProjectSheet = false
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
            .navigationDestination(for: AudioRecording.self) { recording in
                AudioVisualTestView(recording: recording)
            }
            .sheet(isPresented: $showNewProjectSheet) {
                SelectAudioSheetView(onSelection: { recording in
                    showNewProjectSheet = false
                    navigationManager.navigateToEditor(for: recording)
                })
                .presentationBackground(Color.background)
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
        VStack {
            Text("projects list")
        }
    }
}

#Preview {
    ProjectsScreen()
        .preferredColorScheme(.dark)
}
