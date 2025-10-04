import SwiftUI
import ScreenCaptureKit
import Combine

class ScreenCaptureManager: ObservableObject {
    @Published var capturedImage: NSImage?
    private var stream: SCStream?
    private var streamOutput: StreamOutput?
    private var ourWindow: NSWindow?
    var toolbarHeight: CGFloat = 0

    func startCapture(windowFrame: CGRect, window: NSWindow, toolbarHeight: CGFloat = 0) async {
        self.toolbarHeight = toolbarHeight
        self.ourWindow = window

        do {
            // Get available content
            let content = try await SCShareableContent.current

            // Find the display that contains our window
            guard let display = content.displays.first else { return }

            // Find our own window in the shareable content to exclude it
            let ourWindowID = window.windowNumber
            let windowsToExclude = content.windows.filter { $0.windowID == CGWindowID(ourWindowID) }

            // Create a filter to exclude our own window
            let filter = SCContentFilter(display: display, excludingWindows: windowsToExclude)

            // Convert window frame to screen capture coordinates
            let captureRect = convertToScreenCaptureCoordinates(windowFrame: windowFrame, displayHeight: CGFloat(display.height))

            // Configure stream with the window's frame
            let config = SCStreamConfiguration()
            config.sourceRect = captureRect
            config.width = Int(windowFrame.width)
            config.height = Int(windowFrame.height)
            config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
            config.queueDepth = 3

            // Create and start stream
            streamOutput = StreamOutput(captureManager: self)
            stream = SCStream(filter: filter, configuration: config, delegate: nil)

            try stream?.addStreamOutput(streamOutput!, type: .screen, sampleHandlerQueue: .main)
            try await stream?.startCapture()

        } catch {
            print("Failed to start capture: \(error)")
        }
    }

    func updateCapture(windowFrame: CGRect) async {
        guard let stream = stream else { return }

        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else { return }

            // Convert window frame to screen capture coordinates
            let captureRect = convertToScreenCaptureCoordinates(windowFrame: windowFrame, displayHeight: CGFloat(display.height))

            let config = SCStreamConfiguration()
            config.sourceRect = captureRect
            config.width = Int(windowFrame.width)
            config.height = Int(windowFrame.height)
            config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
            config.queueDepth = 3

            try await stream.updateConfiguration(config)
        } catch {
            print("Failed to update capture: \(error)")
        }
    }

    private func convertToScreenCaptureCoordinates(windowFrame: CGRect, displayHeight: CGFloat) -> CGRect {
        // windowFrame comes from convertToScreen which uses Cocoa coordinates (origin bottom-left)
        // ScreenCaptureKit expects coordinates with origin at top-left
        // So we need to flip: top-left Y = displayHeight - bottom-left Y - height
        let flippedY = displayHeight - windowFrame.origin.y - windowFrame.height
        let result = CGRect(
            x: windowFrame.origin.x,
            y: flippedY,
            width: windowFrame.width,
            height: windowFrame.height
        )
        print("DEBUG: displayHeight=\(displayHeight), windowFrame=\(windowFrame), flippedY=\(flippedY), captureRect=\(result)")
        return result
    }

    func stopCapture() async {
        do {
            try await stream?.stopCapture()
            stream = nil
        } catch {
            print("Failed to stop capture: \(error)")
        }
    }
}

class StreamOutput: NSObject, SCStreamOutput {
    weak var captureManager: ScreenCaptureManager?

    init(captureManager: ScreenCaptureManager) {
        self.captureManager = captureManager
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        DispatchQueue.main.async {
            self.captureManager?.capturedImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }
    }
}
