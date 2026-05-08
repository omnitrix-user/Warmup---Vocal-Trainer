//
//  ContentView.swift
//  Warmup
//
//  Created by Qualtech on 08/05/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // TODO: Drop scale_C.m4a into the project bundle (target membership checked) before running.
                Button {
                    audioEngine.play(fileName: "scale_C")
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color(red: 0.95, green: 0.7, blue: 0.3))
                }

                Text(audioEngine.isPlaying ? "Playing" : "Idle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AudioEngine())
}
