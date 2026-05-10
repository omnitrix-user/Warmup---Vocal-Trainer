import Foundation
import Combine
import AVFoundation

final class AudioEngine: ObservableObject {
    @Published var isPlaying: Bool = false

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    /// Exposes the underlying AVAudioEngine input node so PitchDetector can install a tap on it.
    var inputNode: AVAudioInputNode {
        engine.inputNode
    }

    init() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            print("[AudioEngine] Session configured")
        } catch {
            print("[AudioEngine] AVAudioSession setup failed: \(error.localizedDescription)")
        }

        setup()
    }

    private func setup() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        engine.prepare()

        do {
            try engine.start()
            print("[AudioEngine] Engine started")
        } catch {
            print("[AudioEngine] Engine start failed: \(error.localizedDescription)")
        }
    }

    func play(fileName: String, fileExtension: String = "m4a") {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("[AudioEngine] ERROR: Could not find file \(fileName).\(fileExtension) in app bundle")
            return
        }

        do {
            let file = try AVAudioFile(forReading: url)
            print("[AudioEngine] Loaded file: \(fileName).\(fileExtension)")

            playerNode.scheduleFile(file, at: nil, completionHandler: { [weak self] in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    print("[AudioEngine] Playback finished")
                }
            })

            playerNode.play()
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = true
                print("[AudioEngine] Playback started")
            }
        } catch {
            print("[AudioEngine] Playback scheduling failed: \(error.localizedDescription)")
        }
    }

    func playAndWait(fileName: String, fileExtension: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
                print("[AudioEngine] ERROR: Could not find file \(fileName).\(fileExtension) in app bundle")
                continuation.resume()
                return
            }
            do {
                let file = try AVAudioFile(forReading: url)
                playerNode.scheduleFile(file, at: nil) { [weak self] in
                    DispatchQueue.main.async {
                        self?.isPlaying = false
                        print("[AudioEngine] playAndWait finished: \(fileName).\(fileExtension)")
                        continuation.resume()
                    }
                }
                DispatchQueue.main.async { [weak self] in
                    self?.isPlaying = true
                    print("[AudioEngine] playAndWait started: \(fileName).\(fileExtension)")
                }
                playerNode.play()
            } catch {
                print("[AudioEngine] ERROR: Failed to load \(fileName).\(fileExtension): \(error.localizedDescription)")
                continuation.resume()
            }
        }
    }

    func stopPlayback() {
        playerNode.stop()
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
        }
        print("[AudioEngine] Playback stopped")
    }

    /// Installs a tap on the mic input node, restarting the engine so the input pipeline
    /// is properly initialized with a valid format. The handler is invoked from the audio thread
    /// for each incoming buffer; do NOT do heavy work in it.
    func installInputTap(bufferSize: AVAudioFrameCount,
                         handler: @escaping (AVAudioPCMBuffer, Double) -> Void) {
        let wasRunning = engine.isRunning
        if wasRunning {
            engine.stop()
        }

        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)

        let format = inputNode.inputFormat(forBus: 0)
        print("[AudioEngine] Installing input tap. Format sampleRate=\(format.sampleRate), channels=\(format.channelCount)")

        guard format.sampleRate > 0, format.channelCount > 0 else {
            print("[AudioEngine] ERROR: Invalid input format from inputNode. Cannot install tap.")
            if wasRunning {
                do { try engine.start() } catch {
                    print("[AudioEngine] ERROR: Failed to restart engine: \(error.localizedDescription)")
                }
            }
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, _ in
            handler(buffer, format.sampleRate)
        }

        do {
            try engine.start()
            print("[AudioEngine] Engine restarted with input tap installed")
        } catch {
            print("[AudioEngine] ERROR: Failed to restart engine after tap install: \(error.localizedDescription)")
        }
    }

    /// Removes the input tap. Safe to call even if no tap is installed.
    func removeInputTap() {
        engine.inputNode.removeTap(onBus: 0)
        print("[AudioEngine] Input tap removed")
    }
}
