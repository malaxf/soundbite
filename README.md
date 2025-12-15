# Soundbite
Soundbite is an iOS application that transforms audio into dynamic, reactive visual art. Built specifically to bridge the gap between audio production and visual storytelling, it allows users to import audio, customize reactive shaders, and (coming soon) export high-fidelity video clips for social sharing.

## Overview
I built this project to explore the intersection of Digital Signal Processing (DSP) and Metal Shaders. The goal was to create an "audio-reactive OS" where the visuals aren't just random animations, but mathematical representations of the audio frequencies.

## Key Features
- Audio Upload: Upload songs from videos in your camera roll
  
- Audio Analysis: Real-time FFT (Fast Fourier Transform) analysis using AVFoundation and Apple's Accelerate framework.

- Dynamic Shaders: Custom Metal shaders that react in real-time to frequency data.

- Customization: Granular control over primary/secondary colors and shader styles.

- Offline Rendering: A dedicated offline rendering pipeline to export 60fps video.

## Technical Architecture

### Overall
The app uses Swift 6.2 Swift Concurrency, SwiftUI MVVM with stateful Managers and stateless Services.

### Audio Playback
AVAudioEngine with installTap for real-time processing

### Audio Processing
Apple's vDSP (Accelerate) and AFFoundation for FFT and post FFT processing such as normalization, log scaling, and frequency binning.

### Live Visual Rendering
SwiftUI and custom Metal shaders


## Roadmap & Known Issues
This project is a prototype built to demonstrate specific technical capabilities. There are a few areas currently being refactored:

Export Optimization (WIP): The export functionality is functional but currently undergoing optimization. The goal is to improve the export speeds when handling complex shaders and support higher fps and resolution.

Audio Engine Migration: The current implementation uses AVAudioEngine for playback because installTap(onBus:) offers the path of least resistance for retrieving raw PCM data for FFT analysis.

Future Plan: I plan to migrate the playback engine to AVPlayer combined with MTAudioProcessingTap or use an AVSinkNode instead of installTap. This will provide native integration for playback control while on the canvas view (in the case of AVPlayer), and higher fps for real-time visualization.


## Getting Started
- Clone the repo.
- Open soundbite.xcodeproj.
- Build and Run.

Built with SwiftUI, Metal, and a love for music.
