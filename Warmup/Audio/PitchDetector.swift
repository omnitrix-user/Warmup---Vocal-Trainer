import Foundation
import Combine
import AVFoundation

/// Real-time vocal pitch detector.
///
/// Installs an input tap on the shared AudioEngine's mic input node and runs
/// time-domain autocorrelation on incoming audio buffers to estimate the fundamental
/// frequency. Designed for the human voice range (~80 Hz to ~1100 Hz).
///
/// All published properties are updated on the main thread.
final class PitchDetector: ObservableObject {
    @Published private(set) var detectedFrequency: Double = 0
    @Published private(set) var detectedNote: String = "—"
    @Published private(set) var amplitude: Double = 0
    @Published private(set) var isListening: Bool = false
    @Published private(set) var permissionDenied: Bool = false

    private let audioEngine: AudioEngine
    private let bufferSize: AVAudioFrameCount = 2048
    private let processingQueue = DispatchQueue(label: "com.warmup.pitchdetection", qos: .userInitiated)

    // Voice fundamental frequency range (Hz) — used to bound the autocorrelation lag search.
    private let minFrequency: Double = 80.0
    private let maxFrequency: Double = 1100.0

    // Amplitude floor. Below this RMS, treat as silence.
    private let silenceFloor: Float = 0.01

    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
    }

    func start() async {
        let granted = await AVAudioApplication.requestRecordPermission()
        DispatchQueue.main.async { [weak self] in
            self?.permissionDenied = !granted
        }
        guard granted else {
            print("[PitchDetector] ERROR: Microphone permission denied")
            return
        }

        audioEngine.installInputTap(bufferSize: bufferSize) { [weak self] buffer, sampleRate in
            guard let self else { return }
            guard let channelData = buffer.floatChannelData else { return }
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0 else { return }

            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))

            self.processingQueue.async { [weak self] in
                self?.processSamples(samples, sampleRate: sampleRate)
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.isListening = true
        }
        print("[PitchDetector] Started listening")
    }

    func stop() {
        guard isListening else { return }
        audioEngine.removeInputTap()
        DispatchQueue.main.async { [weak self] in
            self?.isListening = false
            self?.detectedFrequency = 0
            self?.amplitude = 0
            self?.detectedNote = "—"
        }
        print("[PitchDetector] Stopped")
    }

    // MARK: - DSP

    private func processSamples(_ samples: [Float], sampleRate: Double) {
        let rms = Self.computeRMS(samples)
        let frequency: Double

        if rms < silenceFloor {
            frequency = 0
        } else {
            frequency = Self.estimateFrequency(samples: samples,
                                               sampleRate: sampleRate,
                                               minFrequency: minFrequency,
                                               maxFrequency: maxFrequency)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.amplitude = Double(rms)

            if frequency >= self.minFrequency && frequency <= self.maxFrequency {
                self.detectedFrequency = frequency
                self.detectedNote = Self.noteName(forFrequency: frequency)
            } else {
                self.detectedFrequency = 0
                self.detectedNote = "—"
            }
        }
    }

    /// RMS amplitude of a buffer. Used as a silence gate before running pitch detection.
    private static func computeRMS(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        var sumSquares: Float = 0
        for sample in samples {
            sumSquares += sample * sample
        }
        return sqrt(sumSquares / Float(samples.count))
    }

    /// Time-domain autocorrelation pitch estimator.
    /// For each candidate lag in the voice frequency range, computes
    /// the correlation between the signal and its lagged copy.
    /// The lag with the maximum correlation corresponds to the fundamental period.
    private static func estimateFrequency(samples: [Float],
                                          sampleRate: Double,
                                          minFrequency: Double,
                                          maxFrequency: Double) -> Double {
        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = Int(sampleRate / minFrequency)
        guard samples.count > maxLag else { return 0 }

        var bestLag = 0
        var bestCorrelation: Float = 0

        for lag in minLag...maxLag {
            var correlation: Float = 0
            let limit = samples.count - lag
            var i = 0
            while i < limit {
                correlation += samples[i] * samples[i + lag]
                i += 1
            }
            if correlation > bestCorrelation {
                bestCorrelation = correlation
                bestLag = lag
            }
        }

        guard bestLag > 0, bestCorrelation > 0 else { return 0 }
        return sampleRate / Double(bestLag)
    }

    /// Converts a frequency in Hz to a musical note name like "A4" or "C#5".
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
