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
    @Published private(set) var isMuted: Bool = false

    private let audioEngine: AudioEngine
    private let bufferSize: AVAudioFrameCount = 2048
    private let processingQueue = DispatchQueue(label: "com.warmup.pitchdetection", qos: .userInitiated)

    // Voice fundamental frequency range (Hz) — used to bound the autocorrelation lag search.
    private let minFrequency: Double = 80.0
    private let maxFrequency: Double = 1100.0

    // Amplitude floor. Below this RMS, treat as silence.
    private let silenceFloor: Float = 0.01

    private var frequencyHistory: [Double] = []
    private let medianWindowSize = 5

    private var stableFrequency: Double = 0

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

    /// Temporarily disables pitch reporting without removing the input tap.
    /// While muted, processSamples discards updates and the published values reset to silence.
    /// Used to suppress detection during scale playback (avoids speaker → mic feedback loop).
    func setMuted(_ muted: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isMuted = muted
            if muted {
                self.detectedFrequency = 0
                self.detectedNote = "—"
                self.amplitude = 0
                self.stableFrequency = 0
            }
        }
    }

    // MARK: - DSP

    private func processSamples(_ samples: [Float], sampleRate: Double) {
        let rms = Self.computeRMS(samples)

        let estimatedFreq: Double
        if rms < silenceFloor {
            estimatedFreq = 0
        } else {
            let yinResult = Self.estimatePitchYIN(samples: samples, sampleRate: sampleRate,
                                                   minFrequency: minFrequency,
                                                   maxFrequency: maxFrequency)
            estimatedFreq = yinResult.confidence >= 0.4 ? yinResult.frequency : 0
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.isMuted else { return }
            self.amplitude = Double(rms)

            let octaveCorrected = self.applyOctaveContinuity(rawFrequency: estimatedFreq)
            let smoothed = self.smoothedFrequency(rawFrequency: octaveCorrected)

            self.detectedFrequency = smoothed
            self.detectedNote = smoothed > 0 ? Self.noteName(forFrequency: smoothed) : "—"
        }
    }

    /// Returns the median of an array of doubles. Empty array returns 0.
    private func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        } else {
            return sorted[mid]
        }
    }

    /// Applies a sliding median filter to the raw frequency estimate.
    /// During silence (raw == 0), buffer is cleared and 0 is returned immediately
    /// so the curve stops cleanly. During voicing, returns the median of the last N samples,
    /// which suppresses single-buffer octave errors and noise spikes.
    private func smoothedFrequency(rawFrequency: Double) -> Double {
        if rawFrequency == 0 {
            frequencyHistory.removeAll()
            return 0
        }
        frequencyHistory.append(rawFrequency)
        if frequencyHistory.count > medianWindowSize {
            frequencyHistory.removeFirst()
        }
        return median(frequencyHistory)
    }

    /// If the raw frequency is approximately 2x or 0.5x the previously stable frequency,
    /// it's almost certainly an octave error from the pitch detector. Snap it to the
    /// previous octave. Tight window (1.95-2.05 or 0.49-0.51) so genuine octave
    /// transitions by the singer pass through after a couple of frames.
    private func applyOctaveContinuity(rawFrequency: Double) -> Double {
        guard rawFrequency > 0 else { return 0 }
        guard stableFrequency > 0 else {
            stableFrequency = rawFrequency
            return rawFrequency
        }

        let ratio = rawFrequency / stableFrequency
        var corrected = rawFrequency

        if ratio > 1.95 && ratio < 2.05 {
            corrected = rawFrequency / 2
        } else if ratio > 0.49 && ratio < 0.51 {
            corrected = rawFrequency * 2
        }

        // Slow drift toward the corrected value (light smoothing, doesn't freeze).
        stableFrequency = stableFrequency * 0.85 + corrected * 0.15
        return corrected
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

    /// YIN pitch detection (Cheveigne & Kawahara 2002).
    /// Returns (frequency in Hz, confidence in 0...1). Confidence near 1.0 means strong periodicity.
    /// Returns (0, 0) if no pitch detected within [minFrequency, maxFrequency].
    private static func estimatePitchYIN(
        samples: [Float],
        sampleRate: Double,
        minFrequency: Double = 80,
        maxFrequency: Double = 1100,
        threshold: Float = 0.15
    ) -> (frequency: Double, confidence: Double) {
        let bufferSize = samples.count
        let halfSize = bufferSize / 2
        guard halfSize > 32 else { return (0, 0) }

        let minTau = max(2, Int(sampleRate / maxFrequency))
        let maxTau = min(halfSize - 1, Int(sampleRate / minFrequency))
        guard maxTau > minTau + 1 else { return (0, 0) }

        // Step 1: Difference function d(tau) for tau in 1..<halfSize
        var diff = [Float](repeating: 0, count: halfSize)
        for tau in 1..<halfSize {
            var sum: Float = 0
            var j = 0
            while j < halfSize {
                let delta = samples[j] - samples[j + tau]
                sum += delta * delta
                j += 1
            }
            diff[tau] = sum
        }

        // Step 2: Cumulative mean normalized difference function d'(tau)
        var cmnd = [Float](repeating: 1, count: halfSize)
        var runningSum: Float = 0
        for tau in 1..<halfSize {
            runningSum += diff[tau]
            cmnd[tau] = runningSum > 0 ? diff[tau] * Float(tau) / runningSum : 1
        }

        // Step 3: Absolute threshold — find smallest tau in [minTau, maxTau] where cmnd < threshold,
        // then walk down to local minimum.
        var foundTau = -1
        var tau = minTau
        while tau <= maxTau {
            if cmnd[tau] < threshold {
                while tau + 1 <= maxTau && cmnd[tau + 1] < cmnd[tau] {
                    tau += 1
                }
                foundTau = tau
                break
            }
            tau += 1
        }
        guard foundTau > 0 else { return (0, 0) }

        // Step 4: Parabolic interpolation around the minimum for sub-sample accuracy
        let refinedTau: Double
        if foundTau > 0 && foundTau < halfSize - 1 {
            let s0 = Double(cmnd[foundTau - 1])
            let s1 = Double(cmnd[foundTau])
            let s2 = Double(cmnd[foundTau + 1])
            let denom = 2.0 * (s0 - 2.0 * s1 + s2)
            refinedTau = abs(denom) > 1e-9
                ? Double(foundTau) + (s0 - s2) / denom
                : Double(foundTau)
        } else {
            refinedTau = Double(foundTau)
        }

        let frequency = sampleRate / refinedTau
        guard frequency >= minFrequency, frequency <= maxFrequency else { return (0, 0) }

        let confidence = Double(max(0, min(1, 1.0 - cmnd[foundTau])))
        return (frequency, confidence)
    }

    /// Returns cents difference between detected frequency and a target note name.
    /// 100 cents = 1 semitone.
    /// Negative = detected is below target (sing higher).
    /// Positive = detected is above target (sing lower).
    /// Returns 0 if either input is invalid.
    static func centsOff(detectedFrequency: Double, targetNote: String) -> Double {
        guard detectedFrequency > 0,
              let targetFrequency = frequencyForNote(targetNote) else {
            return 0
        }
        return 1200 * log2(detectedFrequency / targetFrequency)
    }

    /// Converts a note name like "C4" or "F#5" to its frequency in Hz.
    /// Returns nil for malformed input.
    static func frequencyForNote(_ note: String) -> Double? {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        var nameChars = ""
        var octaveChars = ""
        for char in note {
            if char.isNumber || char == "-" {
                octaveChars.append(char)
            } else {
                nameChars.append(char)
            }
        }
        guard let octave = Int(octaveChars),
              let noteIndex = noteNames.firstIndex(of: nameChars) else {
            return nil
        }
        // MIDI: C4 = 60, A4 = 69
        let midi = 12 * (octave + 1) + noteIndex
        return 440.0 * pow(2.0, Double(midi - 69) / 12.0)
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
