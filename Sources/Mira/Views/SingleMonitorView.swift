import SwiftUI

struct SingleMonitorView: View {
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var engine: CaptureEngine
    @State private var selectedDisplayID: Int = Preferences.shared.selectedDisplayID
    
    var body: some View {
        ZStack {
            // Check if "All Screens" is selected
            if selectedDisplayID == Preferences.allScreensID {
                AllScreensView(windowManager: windowManager)
            } else if windowManager.availableScreens.isEmpty {
                Text("No external monitors detected")
                    .foregroundColor(.secondary)
            } else {
                let screenId = selectedDisplayID
                if let screen = windowManager.getScreen(by: screenId) {
                    MonitorPreview(screen: screen, windowManager: windowManager, engine: engine)
                        .id(screenId) // Force recreate on change
                        .task(id: screenId) {
                            await engine.startCapture(displayID: UInt32(screenId))
                        }
                } else {
                    Text("Select a monitor from the settings menu")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            // Overlay controls on top of the whole view
            ControlsOverlay(windowManager: windowManager, selection: $selectedDisplayID)
        }
        // Allow resizing to very small dimensions (e.g. 100x80)
        .frame(minWidth: 100, minHeight: 80)
    }
}
