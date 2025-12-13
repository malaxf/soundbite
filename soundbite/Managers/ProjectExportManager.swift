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
    
    let fps: Int32 = 60
    let resolution = CGSize(width: 1080, height: 1920)
    
    func export(project: Project, to outputURL: URL) async throws {
        guard let audioURL = project.fileURL else {
            throw ExportError.fileSetupFailed
        }

        let audioReader = try await OfflineAudioReader(audioURL: audioURL)
        let duration = try await AVURLAsset(url: audioURL).load(.duration).seconds

        Log.export.debug("Duration: \(duration)s")
        
        if FileManager.default.fileExists(atPath: outputURL.path()) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: resolution.width,
            AVVideoHeightKey: resolution.height
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: resolution.width,
                kCVPixelBufferHeightKey as String: resolution.height,
                kCVPixelBufferMetalCompatibilityKey as String: true
            ]
        )
        
        writer.add(videoInput)
        try writer.start()
        writer.startSession(atSourceTime: .zero)
        
        guard let shaderType = project.background.shaderType,
              let primary = project.background.primaryShaderColor,
              let secondary = project.background.secondaryShaderColor else {
            // You might want a fallback here, but for now we error out
            throw ExportError.shaderInitializationFailed
        }
        
        let renderer = try await OfflineMetalRenderer(shader: shaderType)
        
        let totalFrames = Int(duration * Double(fps))
        Log.export.info("Starting export: \(totalFrames) frames")
        
        for i in 0..<totalFrames {
                    if writer.status == .failed { throw ExportError.writerFailed }
                    
                    // Wait for input to be ready
                    while !videoInput.isReadyForMoreMediaData {
                        try await Task.sleep(nanoseconds: 10_000_000)
                    }
                    
                    let seconds = Double(i) / Double(fps)
                    let presentationTime = CMTime(value: Int64(i), timescale: fps)
                    
                    // 1. Get Audio Data
                    let fftData = await audioReader.getFrequencyData(at: seconds)
                    
                    // 2. allocate Pixel Buffer
                    guard let pool = adaptor.pixelBufferPool else { throw ExportError.writerFailed }
                    var pixelBufferOut: CVPixelBuffer?
                    
                    let result = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)
                    
                    guard result == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else {
                        Log.export.error("Buffer allocation failed at frame \(i)")
                        throw ExportError.fileSetupFailed
                    }
                    
                    // 3. Render
                    await renderer.render(
                        to: pixelBuffer,
                        time: Float(seconds),
                        size: resolution,
                        primary: primary,
                        secondary: secondary,
                        fftData: fftData
                    )
                    
                    if !adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                        Log.export.error("Failed to append frame at \(seconds)s")
                        throw ExportError.writerFailed
                    }
                    
                    // 5. Cleanup helps prevents memory spikes
                    pixelBufferOut = nil
                    
                    if i % 60 == 0 {
                        let progress = Int(Double(i) / Double(totalFrames) * 100)
                        Log.export.debug("Progress: \(progress)%")
                    }
                }
        
        videoInput.markAsFinished()
        await writer.finishWriting()
        Log.export.info("Export complete")
        
    }
}





private class OfflineAudioReader {
    private let processor = FFTAudioProcessor()
    private var monoSamples: [Float] = []
    private var sampleRate: Double = 0

    // Smoothing: store previous frame's FFT data
    private var previousFFT: [Float]?
    private let smoothingFactor: Float = 0.2 // Lower = smoother transitions


    init(audioURL: URL) throws {
        let file = try AVAudioFile(forReading: audioURL)
        let format = file.processingFormat
        self.sampleRate = format.sampleRate

        self.processor.sampleRate = Float(format.sampleRate)

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else {
            throw ProjectExportManager.ExportError.audioAnalysisFailed
        }

        try file.read(into: buffer)
        self.monoSamples = FFTAudioProcessor.convertBufferToMono(buffer)

        Log.export.debug("Audio loaded: \(monoSamples.count) samples at \(sampleRate)Hz")
    }

    func getFrequencyData(at time: TimeInterval) -> [Float] {
        let index = Int(time * sampleRate)
        let fftSize = processor.sampleSize

        guard index + fftSize < monoSamples.count else {
            return previousFFT ?? [Float](repeating: 0, count: 64)
        }

        let chunk = Array(monoSamples[index..<(index + fftSize)])

        var result = Array(processor.performAndProcessFFT(on: chunk).reversed())

        if result.isEmpty {
            return previousFFT ?? [Float](repeating: 0, count: 64)
        }

        // Apply temporal smoothing to reduce frame-to-frame variation
        if let prev = previousFFT, prev.count == result.count {
            for i in 0..<result.count {
                // Exponential moving average: new = factor * current + (1 - factor) * previous
                result[i] = smoothingFactor * result[i] + (1 - smoothingFactor) * prev[i]
            }
        }

        previousFFT = result
        return result
    }
}




private class OfflineMetalRenderer {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLComputePipelineState?
    var textureCache: CVMetalTextureCache?
    
    init(shader: SoundbiteShader) throws {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            throw ProjectExportManager.ExportError.shaderInitializationFailed
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        // 1. Setup Texture Cache (allows Metal to write to CVPixelBuffers)
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        self.textureCache = cache
        
        // 2. Load the Library and Function
        // Note: We construct the kernel name based on your naming convention in VoidPack.metal
        // e.g., horizontalLinesInVoidReactive -> exportableHorizontalLinesInVoidReactive
        let library = try device.makeDefaultLibrary(bundle: Bundle.main)
        let kernelName = "exportable" + shader.rawValue.prefix(1).uppercased() + shader.rawValue.dropFirst()
        
        guard let function = library.makeFunction(name: kernelName) else {
            Log.export.error("Could not find kernel function: \(kernelName)")
            throw ProjectExportManager.ExportError.shaderInitializationFailed
        }
        
        self.pipelineState = try device.makeComputePipelineState(function: function)
    }
    
    func render(
        to pixelBuffer: CVPixelBuffer,
        time: Float,
        size: CGSize,
        primary: ShaderColor,
        secondary: ShaderColor,
        fftData: [Float]
    ) {
        guard let textureCache = textureCache,
              let pipelineState = pipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }

        let lockResult = CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard lockResult == kCVReturnSuccess else { return }

        // 2. Create Metal Texture from CVPixelBuffer
        var cvTexture: CVMetalTexture?
        let textureStatus = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm, // Must match the writer settings in ProjectExportManager
            Int(size.width),
            Int(size.height),
            0,
            &cvTexture
        )

        guard textureStatus == kCVReturnSuccess,
              let cvTexture = cvTexture,
              let texture = CVMetalTextureGetTexture(cvTexture) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            return
        }

        // 3. Prepare Data
        // Convert ShaderColor (Double) to SIMD3<Float> for Metal
        var prim = SIMD3<Float>(Float(primary.r), Float(primary.g), Float(primary.b))
        var sec = SIMD3<Float>(Float(secondary.r), Float(secondary.g), Float(secondary.b))
        var timeVal = time
        var sizeVal = SIMD2<Float>(Float(size.width), Float(size.height))

        // Encode Commands
        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)

        // Buffer indices match VoidPack.metal signatures:
        // 0: primary, 1: secondary, 2: time, 3: size, 4: fft, 5: fftCount
        encoder.setBytes(&prim, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
        encoder.setBytes(&sec, length: MemoryLayout<SIMD3<Float>>.stride, index: 1)
        encoder.setBytes(&timeVal, length: MemoryLayout<Float>.stride, index: 2)
        encoder.setBytes(&sizeVal, length: MemoryLayout<SIMD2<Float>>.stride, index: 3)

        // Pass FFT array - ensure we always pass valid data
        let safeFFTData: [Float] = fftData.isEmpty ? [Float](repeating: 0, count: 64) : fftData
        var safeFftCount = Int32(safeFFTData.count)

        safeFFTData.withUnsafeBytes { bufferPointer in
            if let baseAddress = bufferPointer.baseAddress {
                encoder.setBytes(baseAddress, length: bufferPointer.count, index: 4)
            }
        }

        encoder.setBytes(&safeFftCount, length: MemoryLayout<Int32>.stride, index: 5)

        // 5. Dispatch Threads
        let w = pipelineState.threadExecutionWidth
        let h = pipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let threadsPerGrid = MTLSizeMake(Int(size.width), Int(size.height), 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        CVMetalTextureCacheFlush(textureCache, 0)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
}




import Photos

extension ProjectExportManager {
    
    func mergeAudio(videoURL: URL, audioURL: URL, outputURL: URL) async throws {
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        
        let composition = AVMutableComposition()
        
        // 1. Load Tracks
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first,
              let compositionVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            throw ExportError.fileSetupFailed
        }
        
        // 2. Define Time Ranges
        // We use the VIDEO duration as the master length.
        let videoDuration = try await videoAsset.load(.duration)
        let videoRange = CMTimeRange(start: .zero, duration: videoDuration)
        
        // Insert Video
        try compositionVideo.insertTimeRange(videoRange, of: videoTrack, at: .zero)
        
        // 3. Insert Audio (Clamped)
        // Ensure we don't try to insert more audio than exists, or longer than the video.
        let audioDuration = try await audioAsset.load(.duration)
        let validAudioDuration = min(videoDuration, audioDuration)
        let audioRange = CMTimeRange(start: .zero, duration: validAudioDuration)
        
        try compositionAudio.insertTimeRange(audioRange, of: audioTrack, at: .zero)
        
        // 4. Export (iOS 18+ API)
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.writerFailed
        }
        
        // Use the modern async export method (Available iOS 18.0+)
        // This throws automatically on failure, so no need to check .status
        try await exportSession.export(to: outputURL, as: .mp4)
    }
    
    func saveToCameraRoll(fileURL: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }
}
