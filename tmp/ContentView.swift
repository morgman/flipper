import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Transparent background
            Color.clear

            // Visual border so user can see window bounds
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.blue.opacity(0.6), lineWidth: 2)
                .background(Color.clear)
        }
        .frame(minWidth: 200, minHeight: 200)
    }
}

#Preview {
    ContentView()
}
