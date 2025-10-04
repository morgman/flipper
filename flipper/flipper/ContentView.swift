import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var captureManager = ScreenCaptureManager()
    @StateObject private var windowObserver = WindowObserver()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Display captured and mirrored screen content
                if let image = captureManager.capturedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(x: -1, y: 1) // Horizontal mirror
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color.black.opacity(0.1)
                }

                // Visual border so user can see window bounds
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.blue.opacity(0.6), lineWidth: 2)
                    .background(Color.clear)
            }
            .frame(minWidth: 200, minHeight: 200)
            .onAppear {
                if let window = NSApplication.shared.windows.first {
                    windowObserver.startObserving(window: window)
                    Task {
                        await captureManager.startCapture(windowFrame: window.frame, window: window)
                    }
                }
            }
            .onChange(of: windowObserver.windowFrame) { _, newFrame in
                Task {
                    await captureManager.updateCapture(windowFrame: newFrame)
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                if let window = NSApplication.shared.windows.first {
                    Task {
                        await captureManager.updateCapture(windowFrame: window.frame)
                    }
                }
            }
        }
    }
}

class WindowObserver: NSObject, ObservableObject {
    @Published var windowFrame: CGRect = .zero
    private var window: NSWindow?

    func startObserving(window: NSWindow) {
        self.window = window
        windowFrame = window.frame

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: window
        )
    }

    @objc private func windowDidMove(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            windowFrame = window.frame
        }
    }

    @objc private func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            windowFrame = window.frame
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

#Preview {
    ContentView()
}
