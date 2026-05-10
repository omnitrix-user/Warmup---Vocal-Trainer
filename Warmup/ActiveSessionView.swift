import SwiftUI
import Combine

struct PitchSnapshot: Identifiable {
    let id = UUID()
    let centsOff: Double
    let amplitude: Double
    let isVoiced: Bool
}

struct ActiveSessionView: View {
    @EnvironmentObject var sessionPlayer: SessionPlayer
    @EnvironmentObject var pitchDetector: PitchDetector
    @Environment(\.dismiss) private var dismiss

    @State private var pitchHistory: [PitchSnapshot] = []
    @State private var demoStartTime: Date = Date()
    @State private var demoVariationSeed: Double = Double.random(in: 0...10)

    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)
    private let maxHistory = 80
    private let visualizationHeight: CGFloat = 180

    // Set to true to capture portfolio screenshots with synthetic curve data.
    // Set back to false before shipping or live demos. The real YIN pipeline
    // is unaffected — this only swaps the data feeding the display.
    private static let demoCaptureMode: Bool = true

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

    private var stepDisplayIndex: Int {
        (sessionPlayer.currentStepIndex ?? 0) + 1
    }

    private var progressFraction: CGFloat {
        guard sessionPlayer.totalSteps > 0 else { return 0 }
        return CGFloat(stepDisplayIndex) / CGFloat(sessionPlayer.totalSteps)
    }

    private var displayedDetectedNote: String {
        if Self.demoCaptureMode, let step = currentStep {
            return step.targetNote
        }
        return pitchDetector.detectedNote
    }

    private var displayedCentsOff: Double {
        if Self.demoCaptureMode {
            return pitchHistory.last?.centsOff ?? 0
        }
        return centsOff
    }

    private var displayedIsInTune: Bool {
        abs(displayedCentsOff) <= 35
    }

    private var primaryButtonIconName: String {
        switch sessionPlayer.state {
        case .paused, .idle, .finished:
            return "play.circle.fill"
        case .playing, .resting, .countingIn(_):
            return "pause.circle.fill"
        }
    }

    private func appendDemoCurvePoint() {
        let elapsed = Date().timeIntervalSince(demoStartTime)
        let seed = demoVariationSeed

        // Phase 1 (0-1.4s): smooth rise from a lowish dip to near-target.
        // Phase 2 (1.4s+): hover near zero cents with three layered wobbles.
        let baseCents: Double
        if elapsed < 1.4 {
            let t = elapsed / 1.4
            let easeOut = 1 - pow(1 - t, 3)               // cubic ease-out
            let startDip = -70 - seed * 1.5               // -70 to -85 cents
            baseCents = startDip * (1 - easeOut)
        } else {
            let p = elapsed - 1.4
            let slowDrift   = sin(p * 0.5 + seed)         * 11
            let mediumWobble = sin(p * 2.1 + seed * 1.7)  * 6
            let fastWobble   = sin(p * 5.3 + seed * 0.4)  * 2.5
            baseCents = slowDrift + mediumWobble + fastWobble
        }

        // Light random jitter so the line looks alive, not mechanical.
        let jitter = Double.random(in: -2.0...2.0)
        let cents = baseCents + jitter

        let snap = PitchSnapshot(
            centsOff: cents,
            amplitude: 0.07,
            isVoiced: true
        )
        pitchHistory.append(snap)
        if pitchHistory.count > maxHistory {
            pitchHistory.removeFirst(pitchHistory.count - maxHistory)
        }
    }

    private func appendPitchSnapshot() {
        if Self.demoCaptureMode {
            appendDemoCurvePoint()
            return
        }
        let voiced = pitchDetector.detectedFrequency > 0 && pitchDetector.amplitude > 0.005
        let snap = PitchSnapshot(
            centsOff: voiced ? centsOff : 0,
            amplitude: pitchDetector.amplitude,
            isVoiced: voiced
        )
        pitchHistory.append(snap)
        if pitchHistory.count > maxHistory {
            pitchHistory.removeFirst(pitchHistory.count - maxHistory)
        }
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
                pitchCurve
                    .padding(.horizontal, 24)
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
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            appendPitchSnapshot()
        }
        .onChange(of: currentStep?.id) { _, _ in
            if Self.demoCaptureMode {
                demoStartTime = Date()
                demoVariationSeed = Double.random(in: 0...10)
            }
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
                .shadow(color: amber.opacity(displayedIsInTune ? 0.7 : 0), radius: 40)
                .animation(.easeInOut(duration: 0.4), value: displayedIsInTune)
        }
    }

    // MARK: - Pitch curve

    @ViewBuilder
    private var pitchCurve: some View {
        Canvas { context, size in
            let middleY = size.height / 2
            let pointSpacing = size.width / CGFloat(maxHistory)

            // In-tune zone — soft green band ±20 cents from the target line
            let zoneHalfHeight = (20.0 / 100.0) * (size.height / 2 - 10)
            let zoneRect = CGRect(
                x: 0,
                y: middleY - CGFloat(zoneHalfHeight),
                width: size.width,
                height: CGFloat(zoneHalfHeight * 2)
            )
            context.fill(Path(zoneRect), with: .color(.green.opacity(0.08)))

            // Target line — dashed amber, the visual reference
            var targetLine = Path()
            targetLine.move(to: CGPoint(x: 0, y: middleY))
            targetLine.addLine(to: CGPoint(x: size.width, y: middleY))
            context.stroke(
                targetLine,
                with: .color(amber.opacity(0.45)),
                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
            )

            // Pitch curve — the user's recent trajectory
            guard !pitchHistory.isEmpty else { return }

            // First pass: collect voiced points into separate segments (gap-aware).
            var segments: [[CGPoint]] = []
            var currentSegment: [CGPoint] = []

            for (idx, snap) in pitchHistory.enumerated() {
                let x = CGFloat(idx) * pointSpacing
                let clamped = max(-100, min(100, snap.centsOff))
                let yOffset = -clamped / 100 * Double(size.height / 2 - 10)
                let y = middleY + CGFloat(yOffset)

                if snap.isVoiced {
                    currentSegment.append(CGPoint(x: x, y: y))
                } else if !currentSegment.isEmpty {
                    segments.append(currentSegment)
                    currentSegment = []
                }
            }
            if !currentSegment.isEmpty {
                segments.append(currentSegment)
            }

            // Second pass: draw each segment with smooth quadratic Bezier curves through midpoints.
            var curvePath = Path()
            for points in segments {
                guard let first = points.first else { continue }
                curvePath.move(to: first)

                if points.count == 1 {
                    // Single point — nothing to curve, render a small dash so it's still visible.
                    curvePath.addLine(to: CGPoint(x: first.x + 1, y: first.y))
                    continue
                }
                if points.count == 2 {
                    curvePath.addLine(to: points[1])
                    continue
                }

                // For 3+ points: draw quadratic curves to midpoints, using each point as the control.
                // This passes the curve through midpoints with each pivot point smoothing the bend.
                for i in 1..<(points.count - 1) {
                    let prev = points[i - 1]
                    let curr = points[i]
                    let mid = CGPoint(x: (prev.x + curr.x) / 2 + (curr.x - prev.x) / 2,
                                      y: (prev.y + curr.y) / 2 + (curr.y - prev.y) / 2)
                    // Simpler form: midpoint between current and next
                    let next = points[i + 1]
                    let midToNext = CGPoint(x: (curr.x + next.x) / 2, y: (curr.y + next.y) / 2)
                    curvePath.addQuadCurve(to: midToNext, control: curr)
                }
                // Close to last point with a straight line so we don't drop it.
                curvePath.addLine(to: points[points.count - 1])
            }

            context.stroke(curvePath, with: .color(.white.opacity(0.9)), lineWidth: 3)

            // Current pitch dot — glowing indicator at the right edge
            if let last = pitchHistory.last, last.isVoiced {
                let clamped = max(-100, min(100, last.centsOff))
                let yOffset = -clamped / 100 * Double(size.height / 2 - 10)
                let y = middleY + CGFloat(yOffset)
                let x = CGFloat(pitchHistory.count - 1) * pointSpacing

                let inTune = abs(last.centsOff) <= 20
                let dotColor: Color = inTune ? .green : .white

                // Soft glow
                let glowRect = CGRect(x: x - 14, y: y - 14, width: 28, height: 28)
                context.fill(Path(ellipseIn: glowRect), with: .color(dotColor.opacity(0.35)))

                // Solid dot
                let dotRect = CGRect(x: x - 6, y: y - 6, width: 12, height: 12)
                context.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
            }
        }
        .frame(height: visualizationHeight)
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
                Text(displayedDetectedNote)
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                feedbackIcon
            }
        }
    }

    @ViewBuilder
    private var feedbackIcon: some View {
        if (Self.demoCaptureMode || pitchDetector.detectedFrequency > 0), currentStep != nil {
            if displayedIsInTune {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            } else if displayedCentsOff < -20 {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange.opacity(0.85))
            } else if displayedCentsOff > 20 {
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
                switch sessionPlayer.state {
                case .idle, .finished:
                    sessionPlayer.start(sequence: demoSequence)
                case .paused:
                    sessionPlayer.resume()
                case .playing, .resting, .countingIn(_):
                    sessionPlayer.pause()
                }
            } label: {
                Image(systemName: primaryButtonIconName)
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
