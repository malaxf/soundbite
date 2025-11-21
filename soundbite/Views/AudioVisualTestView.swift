//
//  AudioVisualTestView.swift
//  soundbite
//
//  Created by Malachi Frazier on 11/15/25.
//

import SwiftUI

struct AudioVisualTestView: View {
    @State var recording: AudioRecording
    
    @State private var audioPlayer = AudioPlayerManager()
    
    private let start = Date.now
    
    var body: some View {
        ZStack {
            
            TimelineView(.animation) { tl in
                let time = start.distance(to: tl.date)
                let frequencyData = Array(audioPlayer.frequencyData.reversed())
                
                Color.black
                    .visualEffect { content, proxy in
                        content
                            .colorEffect(
                                ShaderLibrary.horizontalLinesInVoidReactive(
                                    .float(time),
                                    .float2(proxy.size),
                                    .floatArray(frequencyData)
                                )
                            )
                    }
            }
            .ignoresSafeArea()
            
        }
        .backgroundStyle(Color.background)
        .onAppear {
            guard let url = recording.fileURL else {
                print("No file url found")
                return
            }
            
            audioPlayer.play(url: url)
        }
        .onChange(of: audioPlayer.frequencyData) { old, new in
            print("freq data length: \(new.count)")
            print("raw freq data: \(new)")
        }
    }

}

//#Preview {
//    AudioVisualTestView(recording: AudioRecording)
//}
