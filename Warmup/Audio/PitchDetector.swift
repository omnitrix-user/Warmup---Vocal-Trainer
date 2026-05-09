import Foundation
import Combine
import AVFoundation
import AudioKit
import SoundpipeAudioKit

@MainActor
final class PitchDetector: ObservableObject {
    @Published private(set) var detectedFrequency: Double = 0
    @Published private(set) var detectedNote: String = "—"
    @Published private(set) var amplitude: Double = 0
    @Published private(set) var isListening: Bool = false
    @Published private(set) var permissionDenied: Bool = false

    // Use full module path to disambiguate from our project's AudioEngine class.
    private let engine = AudioKit.AudioEngine()
    private var pitchTap: PitchTap?
    private var muteMixer: Mixer?

    init() {
        configure()
    }

    private func configure() {
        guard let input = engine.input else {
            print("[PitchDetector] No mic input available")
            return
        }

        // Mute output — we don't want to hear ourselves through the speaker.
        let mixer = Mixer(input)
        mixer.volume = 0
        muteMixer = mixer
        engine.output = mixer

        pitchTap = PitchTap(input) { [weak self] pitch, amp in
            let frequency = pitch.first.map { Double($0) } ?? 0
            let amplitude = amp.first.map { Double($0) } ?? 0
            DispatchQueue.main.async {
                self?.handleDetection(frequency: frequency, amplitude: amplitude)
            }
        }
        print("[PitchDetector] Configured")
    }

    func start() async {
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            permissionDenied = true
            print("[PitchDetector] ERROR: Microphone permission denied")
            return
        }
        permissionDenied = false

        do {
            try engine.start()
            pitchTap?.start()
            isListening = true
            print("[PitchDetector] Started listening")
        } catch {
            print("[PitchDetector] ERROR: Engine failed to start: \(error.localizedDescription)")
        }
    }

    func stop() {
        pitchTap?.stop()
        engine.stop()
        isListening = false
        detectedFrequency = 0
        amplitude = 0
        detectedNote = "—"
        print("[PitchDetector] Stopped")
    }

    private func handleDetection(frequency: Double, amplitude: Double) {
        self.amplitude = amplitude

        // Filter out silence and obvious noise.
        guard amplitude > 0.05, frequency > 50 else {
            self.detectedNote = "—"
            self.detectedFrequency = 0
            return
        }

        self.detectedFrequency = frequency
        self.detectedNote = Self.noteName(forFrequency: frequency)
    }

    /// Converts a frequency in Hz to a musical note name like "A4", "C#5".
    static func noteName(forFrequency frequency: Double) -> String {
        guard frequency > 0 else { return "—" }
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let midi = 69.0 + 12.0 * log2(frequency / 440.0)
        let midiRounded = Int(midi.rounded())
        guard midiRounded >= 0 else { return "—" }
        let octave = midiRounded / 12 - 1
        let note = noteNames[((midiRounded % 12) + 12) % 12]
        return "\(note)\(octave)"
    }
}
