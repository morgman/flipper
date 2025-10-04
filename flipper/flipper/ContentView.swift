import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var captureManager = ScreenCaptureManager()
    @StateObject private var windowObserver = WindowObserver()
    @State private var magnification: Double = 1.0
    @State private var flipHorizontal: Bool = true
    @State private var flipVertical: Bool = false
    @State private var toolbarHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            GeometryReader { geometry in
                ZStack {
                    // Display captured and mirrored screen content
                    if let image = captureManager.capturedImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .scaleEffect(x: flipHorizontal ? -1 : 1,
                                       y: flipVertical ? -1 : 1,
                                       anchor: .center)
                            .scaleEffect(magnification)
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
                .contentShape(Rectangle())
                .gesture(DragGesture().onChanged { value in
                    // Make content area draggable for window movement
                    if let window = NSApplication.shared.windows.first {
                        let currentLocation = NSEvent.mouseLocation
                        let newOrigin = NSPoint(
                            x: currentLocation.x - value.translation.width,
                            y: currentLocation.y + value.translation.height
                        )
                        window.setFrameOrigin(newOrigin)
                    }
                })
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        windowObserver.startObserving(window: window)
                        Task {
                            // Get the visible content rect (frame minus title bar)
                            let windowFrame = window.frame
                            let contentHeight = window.contentLayoutRect.height
                            let titleBarHeight = windowFrame.height - contentHeight

                            // Adjust frame to exclude title bar and bottom toolbar
                            var adjustedFrame = windowFrame
                            adjustedFrame.origin.y += titleBarHeight + 8  // Fine-tune adjustment
                            adjustedFrame.size.height = contentHeight - toolbarHeight

                            print("DEBUG: windowFrame=\(windowFrame), contentHeight=\(contentHeight), titleBarHeight=\(titleBarHeight), toolbarHeight=\(toolbarHeight), adjustedFrame=\(adjustedFrame)")
                            await captureManager.startCapture(windowFrame: adjustedFrame, window: window, toolbarHeight: 0)
                        }
                    }
                }
                .onChange(of: windowObserver.windowFrame) { _, newFrame in
                    Task {
                        if let window = NSApplication.shared.windows.first {
                            let windowFrame = window.frame
                            let contentHeight = window.contentLayoutRect.height
                            let titleBarHeight = windowFrame.height - contentHeight

                            var adjustedFrame = windowFrame
                            adjustedFrame.origin.y += titleBarHeight + 8  // Fine-tune adjustment
                            adjustedFrame.size.height = contentHeight - toolbarHeight

                            captureManager.toolbarHeight = 0
                            await captureManager.updateCapture(windowFrame: adjustedFrame)
                        }
                    }
                }
                .onChange(of: geometry.size) { _, newSize in
                    if let window = NSApplication.shared.windows.first {
                        Task {
                            let windowFrame = window.frame
                            let contentHeight = window.contentLayoutRect.height
                            let titleBarHeight = windowFrame.height - contentHeight

                            var adjustedFrame = windowFrame
                            adjustedFrame.origin.y += titleBarHeight + 8  // Fine-tune adjustment
                            adjustedFrame.size.height = contentHeight - toolbarHeight

                            await captureManager.updateCapture(windowFrame: adjustedFrame)
                        }
                    }
                }
            }

            // Toolbar at bottom
            HStack {
                Text("Magnification:")
                    .font(.caption)
                Slider(value: $magnification, in: 0.0...3.0, step: 0.1)
                    .frame(width: 150)
                Text(String(format: "%.1fx", magnification))
                    .font(.caption)
                    .frame(width: 40)

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)

                Text("Flip:")
                    .font(.caption)
                Button(action: { flipHorizontal.toggle() }) {
                    Text("Horizontal")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(flipHorizontal ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)

                Button(action: { flipVertical.toggle() }) {
                    Text("Vertical")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(flipVertical ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            .background(GeometryReader { geometry in
                Color.clear.onAppear {
                    toolbarHeight = geometry.size.height
                    print("DEBUG: Toolbar height = \(toolbarHeight)")
                }
            })
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
