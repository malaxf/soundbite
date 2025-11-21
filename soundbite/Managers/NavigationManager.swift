//
//  NavigationManager.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/15/25.
//

import Foundation
import SwiftUI
import Observation

@Observable
class NavigationManager {
    var path: NavigationPath = NavigationPath()
    
    func navigateToEditor(for recording: AudioRecording) {
        path.append(recording)
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}
