import Foundation
import ScreenCaptureKit
import CoreGraphics
import VideoToolbox

enum CaptureState {
    case idle
    case capturing
    case noPermission
    case error(String)
}

class CaptureEngine: NSObject, SCStreamOutput, SCStreamDelegate, ObservableObject {
    @Published var currentImage: CGImage?
    @Published var state: CaptureState = .idle

    private var stream: SCStream?
    private(set) var displayID: CGDirectDisplayID?

    func startCapture(displayID: CGDirectDisplayID) async {
        stopCapture()
        self.displayID = displayID

        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                await MainActor.run { self.state = .error("Display not found") }
                return
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            configuration.width = Int(display.width)
            configuration.height = Int(display.height)
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            configuration.showsCursor = true
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

            let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInteractive))
            try await stream.startCapture()
            self.stream = stream

            await MainActor.run { self.state = .capturing }

        } catch let error as NSError {
            await MainActor.run {
                // ScreenCaptureKit error -3801 = no permission
                if error.code == -3801 || error.localizedDescription.contains("permission") {
                    self.state = .noPermission
                } else {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    func stopCapture() {
        if let stream = stream {
            stream.stopCapture { _ in }
            self.stream = nil
        }
        self.displayID = nil
        DispatchQueue.main.async {
            self.currentImage = nil
            self.state = .idle
        }
    }

    // MARK: - SCStreamOutput

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let imageBuffer = sampleBuffer.imageBuffer else { return }

        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &cgImage)

        if let cgImage = cgImage {
            DispatchQueue.main.async {
                self.currentImage = cgImage
            }
        }
    }

    // MARK: - SCStreamDelegate

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Mira: Stream stopped with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.state = .error(error.localizedDescription)
        }
    }
}
