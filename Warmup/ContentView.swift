import SwiftUI

struct ContentView: View {
    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)

    var body: some View {
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
    }
}
