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
}
