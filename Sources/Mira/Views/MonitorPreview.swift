import SwiftUI
import CoreGraphics

struct MonitorPreview: View {
    let screen: NSScreen
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var engine: CaptureEngine

    var body: some View {
        GeometryReader { geometry in
            switch engine.state {
            case .capturing:
                if let cgImage = engine.currentImage {
                    Image(cgImage, scale: 1.0, label: Text("Monitor Preview"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                } else {
                    loadingView
                }

            case .noPermission:
                PermissionInlineView(engine: engine)

            case .error(let message):
                errorView(message)

            case .idle:
                loadingView
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            Color.black
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Initializing...")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundColor(.orange)
                Text("Capture Error")
                    .font(.caption)
                    .foregroundColor(.white)
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Shown inline inside the capture window when permission is missing.
/// No separate window, no polling in AppDelegate — just a simple view.
struct PermissionInlineView: View {
    @ObservedObject var engine: CaptureEngine
    @State private var retryTimer: Timer?

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 16) {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                Text("Screen Recording Permission Required")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Mira needs permission to mirror your monitors.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Open Settings and enable Mira")
                    Text("2. If Mira is already ON, toggle OFF then ON")
                    Text("3. Click \"Quit & Reopen\" when macOS asks")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

                HStack(spacing: 12) {
                    Button("Open Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Retry") {
                        retryCapture()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { startAutoRetry() }
        .onDisappear { stopAutoRetry() }
    }

    /// Only retries capture if CGPreflightScreenCaptureAccess confirms permission.
    /// This avoids triggering the system "Allow/Deny" dialog on every retry.
    private func retryCapture() {
        guard CGPreflightScreenCaptureAccess() else { return }
        guard let displayID = engine.displayID else { return }
        let id = displayID
        Task {
            await engine.startCapture(displayID: id)
        }
    }

    private func startAutoRetry() {
        retryTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            retryCapture()
        }
    }

    private func stopAutoRetry() {
        retryTimer?.invalidate()
        retryTimer = nil
    }
}
