import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var sessionPlayer: SessionPlayer
    @EnvironmentObject var pitchDetector: PitchDetector
    @Environment(\.dismiss) private var dismiss

    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)

    // Demo sequence — three steps, each with a different target note.
    // We only have scale_C.wav, so the audio is the same; the target note varies
    // so the pitch matching UI is exercised. Day 5 replaces this with a real
    // exercise library.
    private let demoSequence: [SequenceStep] = [
        SequenceStep(fileName: "scale_C", targetNote: "C4", exerciseName: "Lip trill"),
        SequenceStep(fileName: "scale_C", targetNote: "D4", exerciseName: "Lip trill"),
        SequenceStep(fileName: "scale_C", targetNote: "E4", exerciseName: "Lip trill"),
    ]

    private var currentStep: SequenceStep? {
        guard let idx = sessionPlayer.currentStepIndex,
              idx < demoSequence.count else { return nil }
        return demoSequence[idx]
    }

    private var centsOff: Double {
        guard let step = currentStep, pitchDetector.detectedFrequency > 0 else { return 0 }
        return PitchDetector.centsOff(detectedFrequency: pitchDetector.detectedFrequency,
                                      targetNote: step.targetNote)
    }

    private var isInTune: Bool {
        abs(centsOff) <= 20 && pitchDetector.amplitude > 0.005 && currentStep != nil
    }

    private var stepDisplayIndex: Int {
        (sessionPlayer.currentStepIndex ?? 0) + 1
    }

    private var progressFraction: CGFloat {
        guard sessionPlayer.totalSteps > 0 else { return 0 }
        return CGFloat(stepDisplayIndex) / CGFloat(sessionPlayer.totalSteps)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBlock
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                Spacer()
                targetSection
                Spacer(minLength: 32)
                pitchMeter
                    .padding(.horizontal, 32)
                Spacer(minLength: 32)
                detectedSection
                Spacer()
                bottomControls
                    .padding(.bottom, 48)
            }
        }
        .task {
            await pitchDetector.start()
            sessionPlayer.start(sequence: demoSequence)
        }
        .onDisappear {
            sessionPlayer.stop()
            pitchDetector.stop()
        }
    }

    // MARK: - Top progress

    @ViewBuilder
    private var progressBlock: some View {
        VStack(spacing: 6) {
            HStack {
                Text((currentStep?.exerciseName ?? "—").uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("STEP \(stepDisplayIndex) OF \(sessionPlayer.totalSteps)")
                    .font(.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(amber)
                        .frame(width: max(0, geo.size.width * progressFraction))
                        .animation(.easeOut(duration: 0.4), value: progressFraction)
                }
            }
            .frame(height: 3)
        }
    }

    // MARK: - Target note (the hero element)

    @ViewBuilder
    private var targetSection: some View {
        VStack(spacing: 16) {
            Text("SING THIS")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.secondary)
            Text(currentStep?.targetNote ?? "—")
                .font(.system(size: 128, weight: .bold, design: .monospaced))
                .foregroundStyle(amber)
                .shadow(color: amber.opacity(isInTune ? 0.7 : 0), radius: 40)
                .animation(.easeInOut(duration: 0.4), value: isInTune)
        }
    }

    // MARK: - Pitch meter

    @ViewBuilder
    private var pitchMeter: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.red.opacity(0.35), .orange.opacity(0.35),
                                 .green.opacity(0.5),
                                 .orange.opacity(0.35), .red.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing))
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(isInTune ? 0.85 : 0.25))
                    .frame(width: 56, height: 14)
                    .shadow(color: .green.opacity(isInTune ? 0.6 : 0), radius: 14)
                    .animation(.easeInOut(duration: 0.2), value: isInTune)

                Circle()
                    .fill(.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .white.opacity(0.5), radius: 8)
                    .offset(x: indicatorOffset)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: indicatorOffset)
            }
            .frame(height: 24)

            HStack {
                Text("flat")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(isInTune ? "in tune" : centsOffLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isInTune ? .green : .tertiary)
                    .animation(.easeInOut(duration: 0.2), value: isInTune)
                Spacer()
                Text("sharp")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var centsOffLabel: String {
        guard pitchDetector.detectedFrequency > 0 else { return "—" }
        let rounded = Int(centsOff.rounded())
        if rounded == 0 { return "in tune" }
        return rounded > 0 ? "+\(rounded)¢" : "\(rounded)¢"
    }

    private var indicatorOffset: CGFloat {
        // Map cents (-100 to +100) to a horizontal offset of about ±130pt.
        let clamped = max(-100, min(100, centsOff))
        return CGFloat(clamped) * 1.3
    }

    // MARK: - Detected note + arrow / check

    @ViewBuilder
    private var detectedSection: some View {
        VStack(spacing: 10) {
            Text("YOU'RE SINGING")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Text(pitchDetector.detectedNote)
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                feedbackIcon
            }
        }
    }

    @ViewBuilder
    private var feedbackIcon: some View {
        if pitchDetector.detectedFrequency > 0, currentStep != nil {
            if isInTune {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else if centsOff < -20 {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange.opacity(0.85))
            } else if centsOff > 20 {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange.opacity(0.85))
            }
        }
    }

    // MARK: - Bottom controls

    @ViewBuilder
    private var bottomControls: some View {
        HStack(spacing: 32) {
            Button {
                if sessionPlayer.state == .paused {
                    sessionPlayer.resume()
                } else {
                    sessionPlayer.pause()
                }
            } label: {
                Image(systemName: sessionPlayer.state == .paused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(amber.opacity(0.85))
            }
            Button {
                sessionPlayer.stop()
                pitchDetector.stop()
                dismiss()
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(amber.opacity(0.6))
            }
        }
    }
}
