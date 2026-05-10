import Foundation

struct Routine: Identifiable {
    let id: UUID
    let name: String
    let briefDescription: String
    let durationMinutes: Int
    let iconName: String         // SF Symbol name
    let steps: [SequenceStep]

    init(
        id: UUID = UUID(),
        name: String,
        briefDescription: String,
        durationMinutes: Int,
        iconName: String,
        steps: [SequenceStep]
    ) {
        self.id = id
        self.name = name
        self.briefDescription = briefDescription
        self.durationMinutes = durationMinutes
        self.iconName = iconName
        self.steps = steps
    }
}

extension Routine {
    /// Built-in warmup routines bundled with the app.
    static let builtIn: [Routine] = [
        Routine(
            name: "Quick 5",
            briefDescription: "Morning warmup essentials",
            durationMinutes: 5,
            iconName: "bolt.fill",
            steps: [
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "C4",
                             exerciseName: "Lip Trill"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "D4",
                             exerciseName: "Humming"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "E4",
                             exerciseName: "Five-tone Scale"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "C4",
                             exerciseName: "Vowel Sustain")
            ]
        ),
        Routine(
            name: "Daily 15",
            briefDescription: "Full-range daily practice",
            durationMinutes: 15,
            iconName: "sun.max.fill",
            steps: [
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "C4",
                             exerciseName: "Lip Trill"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "D4",
                             exerciseName: "Humming"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "E4",
                             exerciseName: "Sirens"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "F4",
                             exerciseName: "Five-tone Scale"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "G4",
                             exerciseName: "Vowel Sustain"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "D4",
                             exerciseName: "Octave Slides"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "C4",
                             exerciseName: "Tongue Trill"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "C4",
                             exerciseName: "Cool Hum")
            ]
        ),
        Routine(
            name: "Pre-Show 8",
            briefDescription: "Performance prep",
            durationMinutes: 8,
            iconName: "sparkles",
            steps: [
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "C4",
                             exerciseName: "Lip Trill Activation"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "D4",
                             exerciseName: "Gentle Humming"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "E4",
                             exerciseName: "Vowel Sustain"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "F4",
                             exerciseName: "Five-tone"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "C4",
                             exerciseName: "Yawn-Sigh")
            ]
        ),
        Routine(
            name: "Cool Down 5",
            briefDescription: "Post-singing recovery",
            durationMinutes: 5,
            iconName: "moon.stars.fill",
            steps: [
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "C4",
                             exerciseName: "Soft Humming"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "B3",
                             exerciseName: "Yawn-Sigh"),
                SequenceStep(fileName: "scale_C", fileExtension: "wav",
                             restAfterSeconds: 2, targetNote: "A3",
                             exerciseName: "Lip Releases")
            ]
        )
    ]
}
