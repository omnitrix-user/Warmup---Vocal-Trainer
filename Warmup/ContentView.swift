import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var sessionPlayer: SessionPlayer
    @EnvironmentObject var pitchDetector: PitchDetector

    private let testSequence: [SequenceStep] = [
        SequenceStep(fileName: "scale_C", restAfterSeconds: 2.0),
        SequenceStep(fileName: "scale_C", restAfterSeconds: 2.0),
        SequenceStep(fileName: "scale_C", restAfterSeconds: 2.0),
    ]

    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                pitchSection
                Divider().background(Color.white.opacity(0.1))
                sequenceSection
            }
            .padding()
        }
    }

    @ViewBuilder
    private var pitchSection: some View {
        VStack(spacing: 12) {
            Text("Pitch Detection")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(pitchDetector.detectedNote)
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundStyle(amber)

            Text(String(format: "%.1f Hz", pitchDetector.detectedFrequency))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)

            Text(String(format: "amp %.3f", pitchDetector.amplitude))
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)

            Button {
                Task {
                    if pitchDetector.isListening {
                        pitchDetector.stop()
                    } else {
                        await pitchDetector.start()
                    }
                }
            } label: {
                Text(pitchDetector.isListening ? "Stop Listening" : "Start Listening")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(amber.opacity(0.2))
                    .foregroundStyle(amber)
                    .clipShape(Capsule())
            }

            if pitchDetector.permissionDenied {
                Text("Mic permission denied — enable in Settings")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var sequenceSection: some View {
        VStack(spacing: 12) {
            Text("Sequence Test")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(stateLabel)
                .font(.title3.weight(.medium))

            if let index = sessionPlayer.currentStepIndex {
                Text("Step \(index + 1) of \(sessionPlayer.totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                Button { sessionPlayer.start(sequence: testSequence) } label: {
                    Image(systemName: "play.circle.fill").font(.system(size: 48)).foregroundStyle(amber)
                }
                Button {
                    if sessionPlayer.state == .paused { sessionPlayer.resume() }
                    else { sessionPlayer.pause() }
                } label: {
                    Image(systemName: sessionPlayer.state == .paused ? "play.circle" : "pause.circle")
                        .font(.system(size: 48)).foregroundStyle(amber.opacity(0.7))
                }
                Button { sessionPlayer.stop() } label: {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 48)).foregroundStyle(amber.opacity(0.7))
                }
            }
        }
    }

    private var stateLabel: String {
        switch sessionPlayer.state {
        case .idle: return "Idle"
        case .countingIn(let n): return "Starting in \(n)"
        case .playing: return "Playing"
        case .resting: return "Rest"
        case .paused: return "Paused"
        case .finished: return "Done"
        }
    }
}
