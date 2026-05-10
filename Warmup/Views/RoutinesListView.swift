import SwiftUI

struct RoutinesListView: View {
    @State private var selectedRoutine: Routine?

    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Warmup")
                            .font(.system(size: 44, weight: .semibold, design: .default))
                            .foregroundStyle(.white)

                        Text("Choose a routine to begin")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 32)

                    // Routine cards
                    VStack(spacing: 14) {
                        ForEach(Routine.builtIn) { routine in
                            RoutineCard(routine: routine, amber: amber) {
                                selectedRoutine = routine
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $selectedRoutine) { routine in
            ActiveSessionView(
                steps: routine.steps,
                routineName: routine.name
            )
        }
    }
}

private struct RoutineCard: View {
    let routine: Routine
    let amber: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with subtle amber tint background
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(amber.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: routine.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(amber)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(routine.briefDescription)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()

                // Duration pill
                Text("\(routine.durationMinutes) MIN")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(amber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(amber.opacity(0.15))
                    )

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
