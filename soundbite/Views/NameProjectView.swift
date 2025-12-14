//
//  NameProjectView.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/14/25.
//

import SwiftUI

struct NameProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""
    @FocusState private var isTextFieldFocused: Bool

    let songTitle: String
    let onConfirm: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Name Your Project")
                .font(.title2)
                .foregroundStyle(Color.foreground)

            VStack(alignment: .leading, spacing: 8) {
                Text("Song: \(songTitle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Project Name", text: $projectName)
                    .font(.title3)
                    .padding()
                    .background(Color.container)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(Color.foreground)
                    .focused($isTextFieldFocused)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.container)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .foregroundStyle(Color.foreground)
                }

                Button {
                    onConfirm(projectName.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                } label: {
                    Text("Create")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.container : Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .foregroundStyle(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : Color.white)
                }
                .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

#Preview {
    NameProjectView(songTitle: "My Song") { name in
        print("Project name: \(name)")
    }
    .background(Color.background)
}
