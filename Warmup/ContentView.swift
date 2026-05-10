import SwiftUI

struct ContentView: View {
    // Set to true to force-show onboarding for screenshot capture (independent
    // of the AppStorage first-launch flag). Production value is false.
    private static let forceShowOnboarding: Bool = false

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
