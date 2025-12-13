//
//  AudioPlayerManager.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/19/25.
//

import Observation
import SwiftUI
import AVFoundation

@Observable
class AudioPlayerManager {
    var frequencyData: [Float] = []

    private let audioProcessor = FFTAudioProcessor()
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()

    init() {
        configureAudioSession()
        configureAudioChain()
    }

    func stop() {
        playerNode.stop()
        audioEngine.mainMixerNode.removeTap(onBus: 0)

        Task { @MainActor in
            self.frequencyData = []
        }
    }

    func play(url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path()) else {
            throw SoundbiteError.fileNotFound(url.path())
        }

        do {
            let file = try AVAudioFile(forReading: url)

            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
            ) else {
                throw SoundbiteError.audioPlaybackFailed("Could not create audio buffer")
            }

            try file.read(into: buffer)

            playerNode.stop()
            audioEngine.mainMixerNode.removeTap(onBus: 0)

            audioEngine.disconnectNodeOutput(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: buffer.format)

            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)

            if !audioEngine.isRunning {
                try audioEngine.start()
            }

            installTap()
            playerNode.play()

            Log.audio.info("Playback started: \(url.lastPathComponent)")
        } catch let error as SoundbiteError {
            throw error
        } catch {
            throw SoundbiteError.audioPlaybackFailed(error.localizedDescription)
        }
    }

    private func installTap() {
        let mixerNode = audioEngine.mainMixerNode
        let format = mixerNode.outputFormat(forBus: 0)

        mixerNode.removeTap(onBus: 0)

        if format.sampleRate != Double(audioProcessor.sampleRate) {
            audioProcessor.sampleRate = Float(format.sampleRate)
        }

        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
            guard let self = self else { return }
            guard self.audioEngine.isRunning else { return }
            guard let channelData = buffer.floatChannelData?[0] else { return }

            let frameLength = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            let fftSize = self.audioProcessor.sampleSize

            if samples.count >= fftSize {
                let start = samples.count - fftSize
                let slice = Array(samples[start..<samples.count])
                let magnitudes = self.audioProcessor.performAndProcessFFT(on: slice)

                Task { @MainActor in
                    self.frequencyData = magnitudes
                }
            }
        }
    }

    private func configureAudioChain() {
        audioEngine.attach(playerNode)
    }

    private func configureAudioSession() {
        Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()

            do {
                try session.setCategory(.playback, mode: .default)
                try session.setPreferredIOBufferDuration(0.015)
                try session.setActive(true)
            } catch {
                Log.audio.error(error, context: "Audio session setup failed")
            }
        }
    }
}
