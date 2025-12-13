//
//  SoundbiteError.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/13/25.
//

import Foundation

enum SoundbiteError: LocalizedError {
    case fileNotFound(String)
    case fileTooLarge(Int)
    case fileOperationFailed(String)
    case audioPlaybackFailed(String)
    case audioExtractionFailed(String)
    case noAudioTrack
    case audioSessionFailed(String)
    case projectCreationFailed(String)
    case projectDeletionFailed(String)
    case projectNotFound
    case exportFailed(String)
    case exportWriterFailed
    case shaderInitializationFailed
    case audioAnalysisFailed

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileTooLarge(let sizeMB):
            return "File is too large (\(sizeMB)MB). Maximum size is 1GB."
        case .fileOperationFailed(let reason):
            return "File operation failed: \(reason)"
        case .audioPlaybackFailed(let reason):
            return "Unable to play audio: \(reason)"
        case .audioExtractionFailed(let reason):
            return "Failed to extract audio: \(reason)"
        case .noAudioTrack:
            return "The selected video does not contain an audio track."
        case .audioSessionFailed(let reason):
            return "Audio session error: \(reason)"
        case .projectCreationFailed(let reason):
            return "Failed to create project: \(reason)"
        case .projectDeletionFailed(let reason):
            return "Failed to delete project: \(reason)"
        case .projectNotFound:
            return "Project not found."
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .exportWriterFailed:
            return "Video writer encountered an error."
        case .shaderInitializationFailed:
            return "Failed to initialize visual effects."
        case .audioAnalysisFailed:
            return "Failed to analyze audio for visualization."
        }
    }
}
