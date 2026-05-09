import Foundation

struct SequenceStep: Identifiable, Equatable {
    let id = UUID()
    let fileName: String
    let fileExtension: String
    let restAfterSeconds: Double

    init(fileName: String, fileExtension: String = "wav", restAfterSeconds: Double = 2.0) {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.restAfterSeconds = restAfterSeconds
    }
}
