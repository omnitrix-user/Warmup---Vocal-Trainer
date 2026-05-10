import SwiftUI

struct HistoryView: View {
    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)
    private var sessions: [CompletedSession] { CompletedSession.seedData }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection

                    sectionLabel("ACTIVITY")
                    ActivityHeatmap(sessions: sessions, amber: amber)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                    sectionLabel("STATS")
                    statsGrid
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)

                    sectionLabel("ALL SESSIONS")
                    sessionsList
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("History")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white)
            Text("\(sessions.count) sessions · \(CompletedSession.totalDurationDisplay) total")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 28)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.4)
            .foregroundStyle(.white.opacity(0.45))
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
    }

    private var statsGrid: some View {
        HStack(spacing: 10) {
            StatCard(
                value: CompletedSession.totalDurationDisplay,
                label: "TOTAL TIME",
                amber: amber
            )
            StatCard(
                value: "\(CompletedSession.thisMonthCount)",
                label: "THIS MONTH",
                amber: amber
            )
            StatCard(
                value: CompletedSession.mostUsedRoutine,
                label: "FAVORITE",
                amber: amber
            )
        }
    }

    private var sessionsList: some View {
        VStack(spacing: 1) {
            ForEach(sessions) { session in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(amber.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: session.routineIcon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(amber)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.routineName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                        Text(session.relativeDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Text("\(session.durationMinutes) min")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04))
            }
        }
    }
}

// MARK: - Stat card

private struct StatCard: View {
    let value: String
    let label: String
    let amber: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(amber)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

// MARK: - Activity heatmap

private struct ActivityHeatmap: View {
    let sessions: [CompletedSession]
    let amber: Color

    private let weekCount = 12
    private let cellSize: CGFloat = 16
    private let cellSpacing: CGFloat = 4

    private var sessionsByDay: [Date: Int] {
        let cal = Calendar.current
        var counts: [Date: Int] = [:]
        for session in sessions {
            let day = cal.startOfDay(for: session.completedAt)
            counts[day, default: 0] += 1
        }
        return counts
    }

    /// Sunday-aligned start dates for the most recent N weeks (oldest first, newest last).
    private var weekStartDates: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromSunday = weekday - 1
        guard let thisWeekSunday = cal.date(byAdding: .day, value: -daysFromSunday, to: today) else {
            return []
        }
        var starts: [Date] = []
        for offset in 0..<weekCount {
            if let start = cal.date(byAdding: .weekOfYear, value: -offset, to: thisWeekSunday) {
                starts.append(start)
            }
        }
        return starts.reversed()
    }

    private func date(_ weekStart: Date, addingDays days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: weekStart) ?? weekStart
    }

    private func cellColor(for date: Date) -> Color {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let day = cal.startOfDay(for: date)

        if day > today { return Color.white.opacity(0.02) }

        let count = sessionsByDay[day] ?? 0
        switch count {
        case 0:  return Color.white.opacity(0.06)
        case 1:  return amber.opacity(0.45)
        case 2:  return amber.opacity(0.75)
        default: return amber
        }
    }

    private func dayLabel(_ dayOfWeek: Int) -> String {
        switch dayOfWeek {
        case 1: return "Mon"
        case 3: return "Wed"
        case 5: return "Fri"
        default: return ""
        }
    }

    private var dateRangeText: String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let oldest = weekStartDates.first else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: oldest)) – \(formatter.string(from: today))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 6) {
                // Day labels (Mon / Wed / Fri only)
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { dow in
                        Text(dayLabel(dow))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 26, height: cellSize, alignment: .trailing)
                    }
                }

                // Week columns
                HStack(spacing: cellSpacing) {
                    ForEach(weekStartDates, id: \.self) { weekStart in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { dow in
                                let cellDate = date(weekStart, addingDays: dow)
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(cellColor(for: cellDate))
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            // Footer: date range + intensity legend
            HStack {
                Text(dateRangeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.45))
                    ForEach([0, 1, 2, 3], id: \.self) { count in
                        let color: Color = {
                            switch count {
                            case 0:  return Color.white.opacity(0.06)
                            case 1:  return amber.opacity(0.45)
                            case 2:  return amber.opacity(0.75)
                            default: return amber
                            }
                        }()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: 10, height: 10)
                    }
                    Text("More")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
    }
}
