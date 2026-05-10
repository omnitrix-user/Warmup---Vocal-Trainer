import SwiftUI

struct ContentView: View {
    // SCREENSHOT MODE: set to true to ALWAYS show onboarding (for portfolio capture).
    // Set to false for normal first-launch-only behavior driven by AppStorage.
    // This is independent of the demoCaptureMode flag in ActiveSessionView — flip
    // both for capture, both off for ship.
    private static let forceShowOnboarding: Bool = true

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var dismissedThisSession: Bool = false

    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)

    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingView(
                    hasCompletedOnboarding: $hasCompletedOnboarding,
                    onDismiss: { dismissedThisSession = true }
                )
                    .transition(.opacity)
            } else {
                TabView {
                    TodayView()
                        .tabItem { Label("Today", systemImage: "sun.max.fill") }
                    RoutinesListView()
                        .tabItem { Label("Library", systemImage: "music.note.list") }
                    HistoryView()
                        .tabItem { Label("History", systemImage: "calendar") }
                }
                .tint(amber)
                .preferredColorScheme(.dark)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
    }

    private var shouldShowOnboarding: Bool {
        if dismissedThisSession { return false }
        if Self.forceShowOnboarding { return true }
        return !hasCompletedOnboarding
    }
}
