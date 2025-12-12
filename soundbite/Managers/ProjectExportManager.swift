//
//  ProjectExportManager.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/12/25.
//

import Foundation
import AVFoundation
import CoreImage
import Metal
import SwiftUI

actor ProjectExportManager {
    
    enum ExportError: Error {
        case fileSetupFailed
        case audioAnalysisFailed
        case shaderInitializationFailed
        case writerFailed
    }
    
    func export(project: Project, to outputURL: URL) async throws {
        guard let audioURL = project.fileURL else {
            throw ExportError.fileSetupFailed
        }
        
        
    }
}



private class OfflineAudioReader {
    
}

private class OfflineMetalRenderer {

}
