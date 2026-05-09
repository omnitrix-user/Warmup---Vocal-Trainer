import SwiftUI

@main
struct WarmupApp: App {
    @StateObject private var audioEngine: AudioEngine
    @StateObject private var sessionPlayer: SessionPlayer

    init() {
        let engine = AudioEngine()
        _audioEngine = StateObject(wrappedValue: engine)
        _sessionPlayer = StateObject(wrappedValue: SessionPlayer(audioEngine: engine))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioEngine)
                .environmentObject(sessionPlayer)
                .preferredColorScheme(.dark)
        }
    }
}
