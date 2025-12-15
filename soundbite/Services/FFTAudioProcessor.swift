//
//  FFTAudioProcessor.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/19/25.
//

import Foundation
import AVFAudio
import Accelerate

struct FrequencyBin {
    let start: Int
    let length: Int
}

class FFTAudioProcessor {
    var dft: vDSP.DiscreteFourierTransform<Float>?
    
    var hanningWindow: [Float]
    var imaginaryZeros: [Float]
    
    let sampleSize: Int
    
    public var sampleRate: Float = 48000.0 {
        didSet {
            if oldValue != sampleRate {
                self.setupFrequencyBins(outputCount: 64, sampleRate: sampleRate)
            }
        }
    }
    
    private var bins: [FrequencyBin] = []
    
    init() {
        let sampleSize = 1024
        self.dft = try? vDSP.DiscreteFourierTransform(
            count: sampleSize,
            direction: .forward,
            transformType: .complexReal,
            ofType: Float.self
        )
        
        self.hanningWindow = vDSP.window(
            ofType: Float.self,
            usingSequence: .hanningDenormalized,
            count: sampleSize,
            isHalfWindow: false
        )
        
        self.imaginaryZeros = [Float](repeating: 0.0, count: sampleSize)
        
        self.sampleSize = sampleSize
        
        self.setupFrequencyBins(outputCount: 64, sampleRate: sampleRate)
    }
    
    public func performAndProcessFFT(on inputSamples: [Float]) -> [Float] {
        let rawFFT = self.performFFT(on: inputSamples)
        return self.processFFTData(rawFFT: rawFFT)
    }
    
    // Takes in input samples and returns [Float] that are the frequencies of the snapshot
    public func performFFT(on inputSamples: [Float]) -> [Float] {
        guard inputSamples.count == self.sampleSize else {
            Log.audio.error("Error performing FFT: inputSample.count != self.sampleSize")
            return []
        }
        
        guard let dft = self.dft else {
            Log.audio.error("Error with DFT initialization")
            return []
        }
        
        let windowedInput = vDSP.multiply(inputSamples, self.hanningWindow)
        
        let output = dft.transform(real: windowedInput, imaginary: self.imaginaryZeros)
        
        var magnitudes = vDSP.hypot(output.real, output.imaginary)
        
        let scaleFactor = 1.0 / Float(sampleSize)
        magnitudes = vDSP.multiply(scaleFactor, magnitudes)
        
        return Array(magnitudes[0..<sampleSize / 2])
    }
    
    private func processFFTData(rawFFT: [Float]) -> [Float] {
        // normalize y axis value to db
        let normalizedInput = self.toDb(from: rawFFT)
        // consider logging at the end after binning if performance issues arise...
        // might be able to get away with less operations since bin.count <= rawFFT.count
        
        guard !bins.isEmpty, normalizedInput.count >= 512 else { return [] }
        
        var output = [Float](repeating: 0, count: bins.count)
        
        normalizedInput.withUnsafeBufferPointer { inputPtr in
            // get ptr base address
            guard let baseAddress = inputPtr.baseAddress else { return }
            
            // iterate over buckets, consider doing looping logic somehow inside vDSP if this is too slow in swift
            for (i, bin) in bins.enumerated() {
                
                // get bin slice to pass into vdsp
                let sliceStart = baseAddress.advanced(by: bin.start)
                
                var value: Float = 0.0
                
                // use maxv, for peak detection
                vDSP_maxv(sliceStart, 1, &value, vDSP_Length(bin.length))
                
                // make highs 
                let position = Float(i) / Float(bins.count)
                let weight = 1.0 + (position * position * 2.5)

                output[i] = min(value * weight, 1.0)
            
            }
        }
        
        return output
    }
    
    private func toDb(from amplitudes: [Float]) -> [Float] {
        
        // compute the 20 * log10(x)
        let dbValues = vDSP.amplitudeToDecibels(amplitudes, zeroReference: 1.0)
        
        // clamp values to -60 db
        let clampedDb = vDSP.threshold(dbValues, to: -80.0, with: .clampToThreshold)
        
        // normalize the range to go from 0 to 1
        let shiftedDb = vDSP.add(80.0, clampedDb)
        let normalized = vDSP.multiply(1.0 / 80.0, shiftedDb)
        
        return normalized
    }
    
    private func setupFrequencyBins(outputCount: Int, sampleRate: Float) {
        // these values should be pretty standard among audio
        // need to check different file formats for support though
        // might need to pass sample rate in as well to get these maxFreq and bin width numbers for different fomats
        let minFreq: Float = 20.0
        let maxFreq: Float = (sampleRate / 2.0) * 0.95
        let fftSize = 1024
        let binCount = fftSize / 2
        let binWidth = sampleRate / Float(fftSize)
        
        var newBins: [FrequencyBin] = []
        
        var startIndices: [Int] = []
        
        // get n = outputCount indicies from the fft array that correspond to the start indicies for n buckets
        for i in 0...outputCount {
            // exponent to raise k = (maxFreq / minFreq) to
            let t = Float(i) / Float(outputCount)
            
            // logarithmic mapping formula
            let freq = minFreq * pow(maxFreq / minFreq, t) // k^t
            let index = Int(freq / binWidth)
            
            startIndices.append(index)
        }
        
        // create the bins from the indices array
        for i in 0..<outputCount {
            let start = startIndices[i]
            let end = startIndices[i+1]
            
            // for safety, ensure length is at least 1 so we don't crash vDSP
            // also for safety, ensure we don't go out of bounds
            let safeStart = min(binCount - 1, start)
            let safeEnd = min(binCount, max(safeStart + 1, end))
            let length = safeEnd - safeStart
            
            newBins.append(FrequencyBin(start: safeStart, length: length))
        }
        
        self.bins = newBins
    }
    
    static func convertBufferToMono(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameLength = Int(buffer.frameLength)
        
        // if already mono, just copy
        if buffer.format.channelCount == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        }
        
        var monoSamples = [Float](repeating: 0, count: frameLength)
        if buffer.format.channelCount >= 2 {
            vDSP_vadd(channelData[0], 1, channelData[1], 1, &monoSamples, 1, vDSP_Length(frameLength))
            var divisor: Float = 0.5
            vDSP_vsmul(monoSamples, 1, &divisor, &monoSamples, 1, vDSP_Length(frameLength))
        }
        
        return monoSamples
    }
    
    
    @available(*, deprecated, message: "Do not use this if you want FFT outputs from a live stream.")
    internal func m4aToPCM(data: Data) -> [Float] {
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        
        do {
            
            try data.write(to: tempURL)
            
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            let file = try AVAudioFile(forReading: tempURL)
            
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
            ) else {
                return []
            }
            
            try file.read(into: buffer)
            
            let frameLength = Int(buffer.frameLength)
            
            // if mono, return mono stream
            if buffer.format.channelCount == 1, let channelData = buffer.floatChannelData?[0] {
                return Array(UnsafeBufferPointer(start: channelData, count: frameLength))
            }
            
            // if stereo or greater, just average stereo signal
            else if buffer.format.channelCount > 1,
                    let leftChannel = buffer.floatChannelData?[0],
                    let rightChannel = buffer.floatChannelData?[1] {
                
                var monoSamples = [Float](repeating: 0, count: frameLength)
                
                vDSP_vadd(leftChannel, 1, rightChannel, 1, &monoSamples, 1, vDSP_Length(frameLength))
                
                var divisor: Float = 0.5
                vDSP_vsmul(monoSamples, 1, &divisor, &monoSamples, 1, vDSP_Length(frameLength))
                
                return monoSamples
            }
            
            
        } catch {
            print("Error decoding audio: \(error.localizedDescription)")
        }
        
        return []
    }
}

