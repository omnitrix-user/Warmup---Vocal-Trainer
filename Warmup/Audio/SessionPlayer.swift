import Foundation
import Combine

enum SessionState: Equatable {
    case idle
    case countingIn(Int)
    case playing
    case resting
    case paused
    case finished
}

@MainActor
final class SessionPlayer: ObservableObject {
    @Published private(set) var state: SessionState = .idle
    @Published private(set) var currentStepIndex: Int? = nil
    @Published private(set) var totalSteps: Int = 0

    private let audioEngine: AudioEngine
    private var currentTask: Task<Void, Never>? = nil
    private var pausedAtStepIndex: Int? = nil
    private var currentSequence: [SequenceStep] = []

    init(audioEngine: AudioEngine) {
        self.audioEngine = audioEngine
    }

    func start(sequence: [SequenceStep]) {
        guard !sequence.isEmpty else { return }
        cancelCurrentTask()
        currentSequence = sequence
        totalSteps = sequence.count
        pausedAtStepIndex = nil
        print("[SessionPlayer] Starting sequence with \(sequence.count) steps")
        currentTask = Task { [weak self] in
            await self?.runSequence(from: 0, includeCountIn: true)
        }
    }

    func pause() {
        guard state != .idle, state != .finished, state != .paused else { return }
        pausedAtStepIndex = currentStepIndex
        cancelCurrentTask()
        audioEngine.stopPlayback()
        state = .paused
        print("[SessionPlayer] Paused at step \(pausedAtStepIndex ?? -1)")
    }

    func resume() {
        guard state == .paused, let resumeIndex = pausedAtStepIndex else { return }
        print("[SessionPlayer] Resuming from step \(resumeIndex)")
        currentTask = Task { [weak self] in
            await self?.runSequence(from: resumeIndex, includeCountIn: false)
        }
    }

    func stop() {
        cancelCurrentTask()
        audioEngine.stopPlayback()
        state = .idle
        currentStepIndex = nil
        pausedAtStepIndex = nil
        print("[SessionPlayer] Stopped")
    }

    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }

    private func runSequence(from startIndex: Int, includeCountIn: Bool) async {
        if includeCountIn {
            for n in [3, 2, 1] {
                state = .countingIn(n)
                print("[SessionPlayer] Count-in: \(n)")
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
            }
        }

        for index in startIndex..<currentSequence.count {
            if Task.isCancelled { return }
            currentStepIndex = index
            state = .playing
            print("[SessionPlayer] Playing step \(index + 1)/\(currentSequence.count)")

            let step = currentSequence[index]
            await audioEngine.playAndWait(fileName: step.fileName, fileExtension: step.fileExtension)
            if Task.isCancelled { return }

            if index < currentSequence.count - 1 {
                state = .resting
                print("[SessionPlayer] Resting \(step.restAfterSeconds)s")
                try? await Task.sleep(for: .seconds(step.restAfterSeconds))
                if Task.isCancelled { return }
            }
        }

        state = .finished
        currentStepIndex = nil
        print("[SessionPlayer] Sequence complete")
    }
}
