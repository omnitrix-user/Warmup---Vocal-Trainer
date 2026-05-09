import SwiftUI

struct ContentView: View {
    @EnvironmentObject var audioEngine: AudioEngine
    @EnvironmentObject var sessionPlayer: SessionPlayer

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
                statusBlock
                controls
            }
        }
    }

    @ViewBuilder
    private var statusBlock: some View {
        VStack(spacing: 8) {
            Text(stateLabel)
                .font(.title2.weight(.medium))
                .foregroundStyle(.primary)
            if let index = sessionPlayer.currentStepIndex {
                Text("Step \(index + 1) of \(sessionPlayer.totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: 24) {
            Button {
                sessionPlayer.start(sequence: testSequence)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(amber)
            }

            Button {
                if sessionPlayer.state == .paused {
                    sessionPlayer.resume()
                } else {
                    sessionPlayer.pause()
                }
            } label: {
                Image(systemName: sessionPlayer.state == .paused ? "play.circle" : "pause.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(amber.opacity(0.7))
            }

            Button {
                sessionPlayer.stop()
            } label: {
                Image(systemName: "stop.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(amber.opacity(0.7))
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

#Preview {
    let engine = AudioEngine()
    return ContentView()
        .environmentObject(engine)
        .environmentObject(SessionPlayer(audioEngine: engine))
}
