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
    
    private var audioEngine: AVAudioEngine = AVAudioEngine()
    private var playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    
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
    
    func play(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path()) else {
            print("Error: cannot play audio, file not found at \(url)")
            return
        }
                
        do {
            let file = try AVAudioFile(forReading: url)
            
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
            ) else {
                print("Error: Could not create audio buffer")
                return
            }
            
            try file.read(into: buffer)
            
            // potential clean up from any previous runs
            playerNode.stop()
            audioEngine.mainMixerNode.removeTap(onBus: 0)
            
            audioEngine.disconnectNodeOutput(playerNode)
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: buffer.format)
            
            // get player node ready to play the audio
            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            
            // make sure audio engine is running
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            
            installTap()
                        
            playerNode.play()
            
        } catch {
            print("Error: cannot play audio with code \(error.localizedDescription)")
        }
    }
    
    private func installTap() {
        
        let mixerNode = audioEngine.mainMixerNode
        let format = mixerNode.outputFormat(forBus: 0)
        
        // clear for safety
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
        // Add player to engine
        audioEngine.attach(playerNode)
        
        //audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        
//        do {
//            try audioEngine.start()
//            print("Engine started")
//        } catch {
//            print("Error starting audio engine: \(error)")
//        }
    }
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try session.setPreferredIOBufferDuration(0.015) // buffer send speed
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
}
