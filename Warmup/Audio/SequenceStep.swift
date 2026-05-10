import Foundation

struct SequenceStep: Identifiable, Equatable {
    let id = UUID()
    let fileName: String
    let fileExtension: String
    let restAfterSeconds: Double
    let targetNote: String       // e.g., "C4", "F#5"
    let exerciseName: String

    init(fileName: String,
         fileExtension: String = "wav",
         restAfterSeconds: Double = 2.0,
         targetNote: String,
         exerciseName: String = "Lip trill") {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.restAfterSeconds = restAfterSeconds
        self.targetNote = targetNote
        self.exerciseName = exerciseName
    }
}
