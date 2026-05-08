//
//  WarmupApp.swift
//  Warmup
//
//  Created by Qualtech on 08/05/26.
//

import SwiftUI

@main
struct WarmupApp: App {
    @StateObject private var audioEngine = AudioEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngine)
                .preferredColorScheme(.dark)
        }
    }
}
