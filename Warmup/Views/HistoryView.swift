import SwiftUI

struct HistoryView: View {
    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)
    private var sessions: [CompletedSession] { CompletedSession.seedData }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("History")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("\(sessions.count) sessions · \(CompletedSession.totalMinutes) min total")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 28)

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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
