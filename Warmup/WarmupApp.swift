import SwiftUI

@main
struct WarmupApp: App {
    @StateObject private var audioEngine: AudioEngine
    @StateObject private var sessionPlayer: SessionPlayer
    @StateObject private var pitchDetector: PitchDetector

    init() {
        let engine = AudioEngine()
        _audioEngine = StateObject(wrappedValue: engine)
        _sessionPlayer = StateObject(wrappedValue: SessionPlayer(audioEngine: engine))
        _pitchDetector = StateObject(wrappedValue: PitchDetector(audioEngine: engine))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngine)
                .environmentObject(sessionPlayer)
                .environmentObject(pitchDetector)
                .preferredColorScheme(.dark)
        }
    }
}
