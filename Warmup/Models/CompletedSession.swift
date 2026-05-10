import Foundation

struct CompletedSession: Identifiable {
    let id: UUID
    let routineName: String
    let routineIcon: String
    let completedAt: Date
    let durationMinutes: Int

    init(
        id: UUID = UUID(),
        routineName: String,
        routineIcon: String,
        completedAt: Date,
        durationMinutes: Int
    ) {
        self.id = id
        self.routineName = routineName
        self.routineIcon = routineIcon
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
    }
}

extension CompletedSession {
    /// Hardcoded seed data for portfolio capture and demonstration.
    /// In a production version, this would be replaced by SwiftData-persisted
    /// CompletedSession records written when the user actually completes a routine.
    static let seedData: [CompletedSession] = {
        let cal = Calendar.current
        let now = Date()

        // (daysAgo, hour, minute, routineName, routineIcon, durationMinutes)
        let specs: [(Int, Int, Int, String, String, Int)] = [
            // Current 12-day streak (today, day 1...day 11)
            (0,  8, 14, "Quick 5",     "bolt.fill",       5),
            (1,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (2,  8,  5, "Daily 15",    "sun.max.fill",    15),
            (3, 19, 32, "Pre-Show 8",  "sparkles",        8),
            (4,  8, 12, "Quick 5",     "bolt.fill",       5),
            (5,  8, 30, "Daily 15",    "sun.max.fill",    15),
            (6, 21, 10, "Cool Down 5", "moon.stars.fill", 5),
            (7,  8, 20, "Daily 15",    "sun.max.fill",    15),
            (8,  7, 50, "Quick 5",     "bolt.fill",       5),
            (9,  8, 28, "Daily 15",    "sun.max.fill",    15),
            (10, 18, 45, "Pre-Show 8",  "sparkles",        8),
            (11, 8, 16, "Daily 15",    "sun.max.fill",    15),
            // GAP at day 12 (ends current streak)

            // Earlier 15-day best streak (days 13-27)
            (13, 8,  8, "Daily 15",    "sun.max.fill",    15),
            (14, 8, 14, "Daily 15",    "sun.max.fill",    15),
            (15, 22, 30, "Cool Down 5", "moon.stars.fill", 5),
            (16, 8, 12, "Quick 5",     "bolt.fill",       5),
            (17, 8, 22, "Daily 15",    "sun.max.fill",    15),
            (18, 19,  5, "Pre-Show 8",  "sparkles",        8),
            (19, 8, 34, "Daily 15",    "sun.max.fill",    15),
            (20, 8, 18, "Daily 15",    "sun.max.fill",    15),
            (21, 7, 55, "Quick 5",     "bolt.fill",       5),
            (22, 8, 26, "Daily 15",    "sun.max.fill",    15),
            (23, 21, 40, "Cool Down 5", "moon.stars.fill", 5),
            (24, 8, 20, "Daily 15",    "sun.max.fill",    15),
            (25, 18, 12, "Pre-Show 8",  "sparkles",        8),
            (26, 8, 16, "Daily 15",    "sun.max.fill",    15),
            (27, 8, 22, "Quick 5",     "bolt.fill",       5),
            // Older history (days 28-89) — populates the heatmap with ~3 months of activity.
            (28,  8, 18, "Daily 15",    "sun.max.fill",    15),
            (29,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (30,  8, 12, "Quick 5",     "bolt.fill",       5),
            (32,  8, 14, "Daily 15",    "sun.max.fill",    15),
            (33,  8, 18, "Daily 15",    "sun.max.fill",    15),
            (34, 18, 30, "Pre-Show 8",  "sparkles",        8),
            (35,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (37,  8, 12, "Quick 5",     "bolt.fill",       5),
            (38,  8, 26, "Daily 15",    "sun.max.fill",    15),
            (39,  8, 20, "Daily 15",    "sun.max.fill",    15),
            (40, 22,  0, "Cool Down 5", "moon.stars.fill", 5),
            (41,  8, 16, "Daily 15",    "sun.max.fill",    15),
            (42,  7, 50, "Quick 5",     "bolt.fill",       5),
            (44,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (45,  8, 18, "Daily 15",    "sun.max.fill",    15),
            (48,  8, 14, "Daily 15",    "sun.max.fill",    15),
            (50,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (51, 19, 30, "Pre-Show 8",  "sparkles",        8),
            (52,  8, 18, "Daily 15",    "sun.max.fill",    15),
            (53,  8, 12, "Quick 5",     "bolt.fill",       5),
            (55,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (56,  8, 14, "Daily 15",    "sun.max.fill",    15),
            (58,  8, 18, "Daily 15",    "sun.max.fill",    15),
            (59,  8, 26, "Daily 15",    "sun.max.fill",    15),
            (60, 21, 30, "Cool Down 5", "moon.stars.fill", 5),
            (62,  8, 18, "Daily 15",    "sun.max.fill",    15),
            (63,  8, 12, "Quick 5",     "bolt.fill",       5),
            (64,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (66,  8, 14, "Daily 15",    "sun.max.fill",    15),
            (67, 18, 45, "Pre-Show 8",  "sparkles",        8),
            (70,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (72,  8, 12, "Quick 5",     "bolt.fill",       5),
            (73,  8, 18, "Daily 15",    "sun.max.fill",    15),
            (75,  8, 26, "Daily 15",    "sun.max.fill",    15),
            (78,  8, 14, "Daily 15",    "sun.max.fill",    15),
            (80, 22,  0, "Cool Down 5", "moon.stars.fill", 5),
            (82,  8, 22, "Daily 15",    "sun.max.fill",    15),
            (85,  8, 12, "Quick 5",     "bolt.fill",       5),
            (87,  8, 18, "Daily 15",    "sun.max.fill",    15),
            (89,  8, 22, "Daily 15",    "sun.max.fill",    15),
            // Multi-session days for heatmap visual variety.
            // Some days have morning + evening (tier 2), a couple have 3 sessions (tier 3).
            ( 1, 21, 30, "Cool Down 5", "moon.stars.fill", 5),
            ( 5, 14, 15, "Quick 5",     "bolt.fill",       5),
            ( 5, 21, 45, "Cool Down 5", "moon.stars.fill", 5),
            ( 9, 19, 30, "Pre-Show 8",  "sparkles",        8),
            (14, 21, 15, "Cool Down 5", "moon.stars.fill", 5),
            (17, 12, 30, "Quick 5",     "bolt.fill",       5),
            (17, 21,  0, "Cool Down 5", "moon.stars.fill", 5),
            (22, 19, 45, "Pre-Show 8",  "sparkles",        8),
            (33, 21, 30, "Cool Down 5", "moon.stars.fill", 5),
            (38, 19, 15, "Pre-Show 8",  "sparkles",        8),
            (50, 21,  0, "Cool Down 5", "moon.stars.fill", 5),
            (55, 19, 30, "Pre-Show 8",  "sparkles",        8),
            (62, 21, 45, "Cool Down 5", "moon.stars.fill", 5),
            (75, 21, 15, "Cool Down 5", "moon.stars.fill", 5),
            (82, 19, 30, "Pre-Show 8",  "sparkles",        8),
        ]

        return specs.compactMap { spec -> CompletedSession? in
            let (daysAgo, hour, minute, name, icon, duration) = spec
            guard let dayDate = cal.date(byAdding: .day, value: -daysAgo, to: now) else {
                return nil
            }
            var comps = cal.dateComponents([.year, .month, .day], from: dayDate)
            comps.hour = hour
            comps.minute = minute
            guard let final = cal.date(from: comps) else { return nil }
            return CompletedSession(
                routineName: name,
                routineIcon: icon,
                completedAt: final,
                durationMinutes: duration
            )
        }
        .sorted { $0.completedAt > $1.completedAt }
    }()

    /// Number of consecutive days ending today that contain at least one session.
    static var currentStreak: Int {
        let cal = Calendar.current
        let activeDays = Set(seedData.map { cal.startOfDay(for: $0.completedAt) })
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        while activeDays.contains(checkDate) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    /// Longest consecutive run of days with at least one session.
    static var bestStreak: Int {
        let cal = Calendar.current
        let uniqueDays = Set(seedData.map { cal.startOfDay(for: $0.completedAt) }).sorted()
        var maxRun = 0
        var currentRun = 0
        var prev: Date? = nil
        for day in uniqueDays {
            if let p = prev {
                let diff = cal.dateComponents([.day], from: p, to: day).day ?? 0
                currentRun = (diff == 1) ? currentRun + 1 : 1
            } else {
                currentRun = 1
            }
            maxRun = max(maxRun, currentRun)
            prev = day
        }
        return maxRun
    }

    /// Total minutes practiced across all seed sessions.
    static var totalMinutes: Int {
        seedData.reduce(0) { $0 + $1.durationMinutes }
    }

    /// Most-used routine across all sessions, by name.
    static var mostUsedRoutine: String {
        let counts = seedData.reduce(into: [String: Int]()) { result, session in
            result[session.routineName, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }

    /// Number of sessions completed this calendar month.
    static var thisMonthCount: Int {
        let cal = Calendar.current
        guard let monthStart = cal.dateInterval(of: .month, for: Date())?.start else { return 0 }
        return seedData.filter { $0.completedAt >= monthStart }.count
    }

    /// Total practice time formatted as "Xh Ym".
    static var totalDurationDisplay: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        return "\(hours)h \(minutes)m"
    }
}

extension CompletedSession {
    /// Friendly relative date like "Today, 8:14 AM" or "3 days ago".
    var relativeDescription: String {
        let cal = Calendar.current
        let now = Date()
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: completedAt), to: cal.startOfDay(for: now)).day ?? 0

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: completedAt)

        switch days {
        case 0:  return "Today, \(timeString)"
        case 1:  return "Yesterday, \(timeString)"
        case 2...6: return "\(days) days ago"
        default: return "\(days) days ago"
        }
    }
}
