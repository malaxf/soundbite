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
import Photos

actor ProjectExportManager {
    
    enum ExportError: Error {
        case fileSetupFailed
        case audioAnalysisFailed
        case shaderInitializationFailed
        case writerFailed
    }
    
    let fps: Int32 = 60
    let resolution = CGSize(width: 1080, height: 1920)
    
    func export(
        project: Project,
        to outputURL: URL,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws {
        guard let audioURL = project.fileURL else {
            throw ExportError.fileSetupFailed
        }

        Log.export.debug("[TIMING] Starting audio reader init...")
        let audioReader = try await OfflineAudioReader(audioURL: audioURL)
        Log.export.debug("[TIMING] Audio reader init complete")

        Log.export.debug("[TIMING] Loading duration...")
        let duration = try await AVURLAsset(url: audioURL).load(.duration).seconds
        Log.export.debug("Duration: \(duration)s")

        if FileManager.default.fileExists(atPath: outputURL.path()) {
            try FileManager.default.removeItem(at: outputURL)
        }

        Log.export.debug("[TIMING] Creating AVAssetWriter...")
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        Log.export.debug("[TIMING] AVAssetWriter instance created")

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: resolution.width,
            AVVideoHeightKey: resolution.height
        ]

        Log.export.debug("[TIMING] Creating AVAssetWriterInput...")
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        Log.export.debug("[TIMING] AVAssetWriterInput created")

        Log.export.debug("[TIMING] Creating PixelBufferAdaptor...")
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: resolution.width,
                kCVPixelBufferHeightKey as String: resolution.height,
                kCVPixelBufferMetalCompatibilityKey as String: true
            ]
        )
        Log.export.debug("[TIMING] PixelBufferAdaptor created")

        Log.export.debug("[TIMING] Adding input to writer...")
        writer.add(videoInput)
        Log.export.debug("[TIMING] Input added")

        await Task.yield()

        Log.export.debug("[TIMING] Calling writer.start()...")
        try writer.start()
        Log.export.debug("[TIMING] writer.start() complete")

        Log.export.debug("[TIMING] Starting session...")
        writer.startSession(atSourceTime: .zero)
        Log.export.debug("[TIMING] AVAssetWriter ready")

        guard let shaderType = project.background.shaderType,
              let primary = project.background.primaryShaderColor,
              let secondary = project.background.secondaryShaderColor else {
            throw ExportError.shaderInitializationFailed
        }

        Log.export.debug("[TIMING] Creating Metal renderer...")
        let renderer = try await OfflineMetalRenderer(shader: shaderType)
        Log.export.debug("[TIMING] Metal renderer ready")

        let totalFrames = Int(duration * Double(fps))
        Log.export.info("Starting export: \(totalFrames) frames")

        for i in 0..<totalFrames {
            try Task.checkCancellation()

            if writer.status == .failed { throw ExportError.writerFailed }

            while !videoInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000)
            }

            let seconds = Double(i) / Double(fps)
            let presentationTime = CMTime(value: Int64(i), timescale: fps)
            let fftData = await audioReader.getFrequencyData(at: seconds)

            guard let pool = adaptor.pixelBufferPool else { throw ExportError.writerFailed }
            var pixelBufferOut: CVPixelBuffer?

            let result = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)

            guard result == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else {
                Log.export.error("Buffer allocation failed at frame \(i)")
                throw ExportError.fileSetupFailed
            }

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
            
            pixelBufferOut = nil

            let progress = Double(i + 1) / Double(totalFrames)
            onProgress(progress)

            if i % 60 == 0 {
                Log.export.debug("Progress: \(Int(progress * 100))%")
            }
        }

        await renderer.waitForCompletion()

        videoInput.markAsFinished()
        await writer.finishWriting()
        Log.export.info("Export complete")
    }
}





private class OfflineAudioReader {
    private let processor = FFTAudioProcessor()
    private var monoSamples: [Float] = []
    private var sampleRate: Double = 0

    private var previousFFT: [Float]?
    private let smoothingFactor: Float = 0.2


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

        if let prev = previousFFT, prev.count == result.count {
            for i in 0..<result.count {
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

    private let inflightSemaphore = DispatchSemaphore(value: 3)

    init(shader: SoundbiteShader) throws {
        Log.export.debug("[TIMING] Metal: Creating device...")
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            throw ProjectExportManager.ExportError.shaderInitializationFailed
        }
        Log.export.debug("[TIMING] Metal: Device created")

        self.device = device
        self.commandQueue = commandQueue

        Log.export.debug("[TIMING] Metal: Creating texture cache...")
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        self.textureCache = cache
        Log.export.debug("[TIMING] Metal: Texture cache created")

        Log.export.debug("[TIMING] Metal: Loading library...")
        let library = try device.makeDefaultLibrary(bundle: Bundle.main)
        let kernelName = "exportable" + shader.rawValue.prefix(1).uppercased() + shader.rawValue.dropFirst()
        Log.export.debug("[TIMING] Metal: Library loaded, finding function \(kernelName)...")

        guard let function = library.makeFunction(name: kernelName) else {
            Log.export.error("Could not find kernel function: \(kernelName)")
            throw ProjectExportManager.ExportError.shaderInitializationFailed
        }
        Log.export.debug("[TIMING] Metal: Function found, creating pipeline state...")

        self.pipelineState = try device.makeComputePipelineState(function: function)
        Log.export.debug("[TIMING] Metal: Pipeline state created")
    }
    
    func render(
        to pixelBuffer: CVPixelBuffer,
        time: Float,
        size: CGSize,
        primary: ShaderColor,
        secondary: ShaderColor,
        fftData: [Float]
    ) {
        inflightSemaphore.wait()

        guard let textureCache = textureCache,
              let pipelineState = pipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            inflightSemaphore.signal()
            return
        }

        let lockResult = CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard lockResult == kCVReturnSuccess else {
            inflightSemaphore.signal()
            return
        }

        var cvTexture: CVMetalTexture?
        let textureStatus = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm, // match the writer settings in ProjectExportManager
            Int(size.width),
            Int(size.height),
            0,
            &cvTexture
        )

        guard textureStatus == kCVReturnSuccess,
              let cvTexture = cvTexture,
              let texture = CVMetalTextureGetTexture(cvTexture) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            inflightSemaphore.signal()
            return
        }

        var prim = SIMD3<Float>(Float(primary.r), Float(primary.g), Float(primary.b))
        var sec = SIMD3<Float>(Float(secondary.r), Float(secondary.g), Float(secondary.b))
        var timeVal = time
        var sizeVal = SIMD2<Float>(Float(size.width), Float(size.height))

        encoder.setComputePipelineState(pipelineState)
        encoder.setTexture(texture, index: 0)
        
        encoder.setBytes(&prim, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
        encoder.setBytes(&sec, length: MemoryLayout<SIMD3<Float>>.stride, index: 1)
        encoder.setBytes(&timeVal, length: MemoryLayout<Float>.stride, index: 2)
        encoder.setBytes(&sizeVal, length: MemoryLayout<SIMD2<Float>>.stride, index: 3)

        let safeFFTData: [Float] = fftData.isEmpty ? [Float](repeating: 0, count: 64) : fftData
        var safeFftCount = Int32(safeFFTData.count)

        safeFFTData.withUnsafeBytes { bufferPointer in
            if let baseAddress = bufferPointer.baseAddress {
                encoder.setBytes(baseAddress, length: bufferPointer.count, index: 4)
            }
        }

        encoder.setBytes(&safeFftCount, length: MemoryLayout<Int32>.stride, index: 5)

        let w = pipelineState.threadExecutionWidth
        let h = pipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let threadsPerGrid = MTLSizeMake(Int(size.width), Int(size.height), 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()

        let semaphore = inflightSemaphore
        commandBuffer.addCompletedHandler { [textureCache] _ in
            CVMetalTextureCacheFlush(textureCache, 0)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            semaphore.signal()
        }
        commandBuffer.commit()
    }

    func waitForCompletion() {
        for _ in 0..<3 {
            inflightSemaphore.wait()
        }
        
        for _ in 0..<3 {
            inflightSemaphore.signal()
        }
    }
}


extension ProjectExportManager {
    
    func mergeAudio(videoURL: URL, audioURL: URL, outputURL: URL) async throws {
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        
        let composition = AVMutableComposition()
        
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first,
              let compositionVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            throw ExportError.fileSetupFailed
        }
        
        let videoDuration = try await videoAsset.load(.duration)
        let videoRange = CMTimeRange(start: .zero, duration: videoDuration)
        
        try compositionVideo.insertTimeRange(videoRange, of: videoTrack, at: .zero)
        
        let audioDuration = try await audioAsset.load(.duration)
        let validAudioDuration = min(videoDuration, audioDuration)
        let audioRange = CMTimeRange(start: .zero, duration: validAudioDuration)
        
        try compositionAudio.insertTimeRange(audioRange, of: audioTrack, at: .zero)
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.writerFailed
        }
        
        try await exportSession.export(to: outputURL, as: .mp4)
    }
    
    func saveToCameraRoll(fileURL: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }
}
