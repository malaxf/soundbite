//
//  Logger.swift
//  soundbite
//
//  Created by Malachi Frazier on 12/13/25.
//

import Foundation
import os

nonisolated let Log = SBLog()

nonisolated
struct SBLog {
    let audio = SBLogger(category: "Audio")
    let project = SBLogger(category: "Project")
    let export = SBLogger(category: "Export")
    let fileService = SBLogger(category: "FileService")
    let general = SBLogger(category: "General")
}

nonisolated
struct SBLogger {
    private let logger: Logger

    init(category: String) {
        self.logger = Logger(subsystem: "com.soundbite", category: category)
    }

    func info(_ message: String) { logger.info("\(message)") }
    func debug(_ message: String) { logger.debug("\(message)") }
    func error(_ message: String) { logger.error("\(message)") }
    func error(_ error: Error, context: String? = nil) {
        if let context {
            logger.error("\(context): \(error.localizedDescription)")
        } else {
            logger.error("\(error.localizedDescription)")
        }
    }
}
