import SwiftUI

struct RangeSelectorView: View {
    @Environment(\.dismiss) private var dismiss

    // MIDI range: C2 (36) to C6 (84) = 48 semitones spanning 4 octaves.
    private let lowestMidi = 36
    private let highestMidi = 84
    private var totalSemitones: Int { highestMidi - lowestMidi }

    // Defaults — a generic tenor range (C3 → C5).
    @State private var lowNoteMidi: Int = 48
    @State private var highNoteMidi: Int = 72

    // Drag-tracking state (captures starting value to support relative drags).
    @State private var dragStartHighMidi: Int? = nil
    @State private var dragStartLowMidi: Int? = nil

    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)
    private let minGap = 5         // semitones between low and high
    private let pickerHeight: CGFloat = 380
    private var trackTopPadding: CGFloat { 20 }
    private var trackHeight: CGFloat { pickerHeight - 40 }
    private var semitoneHeight: CGFloat { trackHeight / CGFloat(totalSemitones) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer().frame(height: 28)
                voiceTypeSection
                Spacer().frame(height: 36)
                rangePicker
                    .padding(.horizontal, 28)
                Spacer()
                Text("Drag the handles to set your comfortable range")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .foregroundStyle(.white.opacity(0.65))
            Spacer()
            Text("Voice Range")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Button("Save") { dismiss() }
                .foregroundStyle(amber)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Voice type display

    private var voiceTypeSection: some View {
        VStack(spacing: 10) {
            Text("YOUR VOICE TYPE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(.white.opacity(0.5))

            Text(voiceType)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(amber)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: voiceType)

            Text("\(noteName(forMidi: lowNoteMidi))  →  \(noteName(forMidi: highNoteMidi))")
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    // MARK: - Range picker

    private var rangePicker: some View {
        ZStack(alignment: .topLeading) {
            // Octave guide lines + labels (C2 .. C6)
            ForEach([84, 72, 60, 48, 36], id: \.self) { midi in
                HStack(spacing: 10) {
                    Text(noteName(forMidi: midi))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.42))
                        .frame(width: 32, alignment: .trailing)
                    Rectangle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 90, height: 1)
                }
                .position(x: 76, y: yForMidi(midi))
            }

            // Vertical track
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 4, height: trackHeight)
                .position(x: 150, y: trackTopPadding + trackHeight / 2)

            // Range bar (gradient between handles)
            let highY = yForMidi(highNoteMidi)
            let lowY = yForMidi(lowNoteMidi)
            LinearGradient(
                colors: [amber.opacity(0.85), amber.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 4, height: max(0, lowY - highY))
            .position(x: 150, y: (highY + lowY) / 2)
            .animation(.interactiveSpring(response: 0.25), value: highNoteMidi)
            .animation(.interactiveSpring(response: 0.25), value: lowNoteMidi)

            // High handle
            handleView(isHigh: true)
                .position(x: 150, y: highY)

            // Low handle
            handleView(isHigh: false)
                .position(x: 150, y: lowY)
        }
        .frame(height: pickerHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handleView(isHigh: Bool) -> some View {
        let midi = isHigh ? highNoteMidi : lowNoteMidi
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(amber)
                    .frame(width: 28, height: 28)
                    .shadow(color: amber.opacity(0.5), radius: 7, x: 0, y: 2)
                Circle()
                    .stroke(.white.opacity(0.95), lineWidth: 2)
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isHigh ? "HIGH" : "LOW")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.45))
                Text(noteName(forMidi: midi))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 140, alignment: .leading)
        .contentShape(Rectangle())
        .gesture(dragGesture(isHigh: isHigh))
    }

    private func dragGesture(isHigh: Bool) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let semitoneDelta = -Int(round(value.translation.height / semitoneHeight))
                if isHigh {
                    if dragStartHighMidi == nil { dragStartHighMidi = highNoteMidi }
                    let newMidi = (dragStartHighMidi ?? highNoteMidi) + semitoneDelta
                    highNoteMidi = max(lowNoteMidi + minGap, min(highestMidi, newMidi))
                } else {
                    if dragStartLowMidi == nil { dragStartLowMidi = lowNoteMidi }
                    let newMidi = (dragStartLowMidi ?? lowNoteMidi) + semitoneDelta
                    lowNoteMidi = max(lowestMidi, min(highNoteMidi - minGap, newMidi))
                }
            }
            .onEnded { _ in
                dragStartHighMidi = nil
                dragStartLowMidi = nil
            }
    }

    // MARK: - Math helpers

    private func yForMidi(_ midi: Int) -> CGFloat {
        let normalized = CGFloat(highestMidi - midi) / CGFloat(totalSemitones)
        return trackTopPadding + normalized * trackHeight
    }

    private func noteName(forMidi midi: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let octave = (midi / 12) - 1
        let pitchClass = midi % 12
        return "\(names[pitchClass])\(octave)"
    }

    // MARK: - Voice classification

    private var voiceType: String {
        let high = highNoteMidi
        let low = lowNoteMidi

        // Approximate ranges by upper limit (with floor sanity check).
        // MIDI: C3=48, E4=64, G4=67, C5=72, E5=76, G5=79, A5=81, C6=84.
        if high <= 64 && low <= 50 { return "Bass" }
        if high <= 67 && low <= 53 { return "Baritone" }
        if high <= 72 && low <= 57 { return "Tenor" }
        if high <= 76 && low >= 53 { return "Alto" }
        if high <= 81 && low >= 57 { return "Mezzo-Soprano" }
        if high >= 79 && low >= 60 { return "Soprano" }
        return "Custom"
    }
}

#Preview {
    RangeSelectorView()
}
