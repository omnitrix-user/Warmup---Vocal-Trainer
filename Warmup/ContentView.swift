import SwiftUI

struct ContentView: View {
    @State private var showActiveSession = false
    private let amber = Color(red: 0.95, green: 0.7, blue: 0.3)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()
                Text("Warmup")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                Text("A vocal warmup companion for singers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showActiveSession = true
                } label: {
                    Text("Start Warmup")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(amber)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 64)
            }
        }
        .fullScreenCover(isPresented: $showActiveSession) {
            ActiveSessionView()
        }
    }
}
