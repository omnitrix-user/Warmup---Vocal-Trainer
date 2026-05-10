import SwiftUI

struct TodayView: View {
    @State private var showingRangeSelector = false

    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)

    private var sessions: [CompletedSession] { CompletedSession.seedData }
    private var current: Int { CompletedSession.currentStreak }
    private var best: Int { CompletedSession.bestStreak }
    private var lastSession: CompletedSession? { sessions.first }
    private var recentSessions: [CompletedSession] {
        Array(sessions.dropFirst().prefix(4))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerBar
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 28)

                    streakCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)

                    if let last = lastSession {
                        sectionLabel("CONTINUE")
                        ContinueCard(session: last, amber: amber)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                    }

                    sectionLabel("RECENT SESSIONS")
                    VStack(spacing: 1) {
                        ForEach(recentSessions) { session in
                            RecentSessionRow(session: session, amber: amber)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingRangeSelector) {
            RangeSelectorView()
        }
    }

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                Text("Today")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button {
                showingRangeSelector = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.top, 20)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Welcome back"
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.4)
            .foregroundStyle(.white.opacity(0.45))
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
    }

    private var streakCard: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(amber.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: "flame.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(amber)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(current)")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                    Text("day streak")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Text("Best: \(best) days")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct ContinueCard: View {
    let session: CompletedSession
    let amber: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(amber.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: session.routineIcon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(amber)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.routineName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                Text(session.relativeDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            ZStack {
                Circle().fill(amber).frame(width: 44, height: 44)
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct RecentSessionRow: View {
    let session: CompletedSession
    let amber: Color

    var body: some View {
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
