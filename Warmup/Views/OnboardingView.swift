import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    let onDismiss: () -> Void

    @State private var currentPage: Int = 0

    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                pageView(
                    icon: "music.mic",
                    title: "Warmup",
                    subtitle: "Train your voice, every day.",
                    isHero: true
                )
                .tag(0)

                pageView(
                    icon: "waveform.path",
                    title: "Real-time Pitch Tracking",
                    subtitle: "See your voice as you sing.\nMatch every note with precision.",
                    isHero: false
                )
                .tag(1)

                pageView(
                    icon: "calendar.badge.clock",
                    title: "Build the Habit",
                    subtitle: "Daily routines. Personal range.\nA practice journal that grows with you.",
                    isHero: false
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                Spacer()
                pageIndicator
                    .padding(.bottom, 24)
                primaryButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func pageView(icon: String, title: String, subtitle: String, isHero: Bool) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(amber.opacity(0.18))
                    .frame(width: 180, height: 180)
                Circle()
                    .strokeBorder(amber.opacity(0.4), lineWidth: 1)
                    .frame(width: 180, height: 180)
                Image(systemName: icon)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(amber)
            }

            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: isHero ? 56 : 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.bottom, 180)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? amber : Color.white.opacity(0.25))
                    .frame(width: index == currentPage ? 26 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
            }
        }
    }

    private var primaryButton: some View {
        Button {
            if currentPage < 2 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage += 1
                }
            } else {
                hasCompletedOnboarding = true
                onDismiss()
            }
        } label: {
            Text(currentPage == 2 ? "Begin" : "Continue")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(amber)
                )
        }
    }
}

#Preview {
    OnboardingView(
        hasCompletedOnboarding: .constant(false),
        onDismiss: {}
    )
}
