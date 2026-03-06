import SwiftUI
import AppKit

class WindowManager: NSObject, ObservableObject {
    @Published var windows: [NSWindow] = []  // Support multiple windows
    private var engines: [NSWindow: CaptureEngine] = [:] // Map windows to their capture engines
    
    @Published var isStopping: Bool = false
    
    @Published var availableScreens: [Int] = []
    
    // Listen to preferences
    private var alwaysOnTopObserver: NSObjectProtocol?
    
    override init() {
        super.init()
    }

    func start() {
        // Initial setup
        refreshScreens()
        updateWindows()
        
        // Listen for screen configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Observe UserDefaults (AppStorage backing)
        alwaysOnTopObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateLevels()
        }
    }

    @objc func screenConfigurationChanged() {
        DispatchQueue.main.async {
            self.refreshScreens()
            // We might not need to fully recreate the window, just update the views?
            // But for simplicity, let's keep the window but maybe refresh state.
            // Actually, if a screen is added/removed, the picker in SingleMonitorView needs to update.
            // Since `availableScreens` is @Published, the view should update automatically if observed.
            // However, ensure the window itself is still valid.
        }
    }
    
    func refreshScreens() {
        availableScreens = NSScreen.screens.compactMap { screen in
             guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return nil }
             return number.intValue
        }
        
        // Ensure selected ID is valid
        if !availableScreens.contains(Preferences.shared.selectedDisplayID) {
            if let first = availableScreens.first {
                Preferences.shared.selectedDisplayID = first
            }
        }
    }
    
    func getScreen(by id: Int) -> NSScreen? {
        return NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return false }
            return number.intValue == id
        }
    }
    
    func screenName(for id: Int) -> String {
        return getScreen(by: id)?.localizedName ?? "Display \(id)"
    }

    func updateWindows() {
        if windows.isEmpty {
            createWindow()
        }
    }
    
    private func createWindow() {
        createNewWindow()
    }
    
    func createNewWindow() {
        // Calculate new window position
        var contentRect = NSRect(x: 100, y: 100, width: 600, height: 400)
        
        if let lastWindow = windows.last {
            let offset: CGFloat = 20
            contentRect.origin.x = lastWindow.frame.origin.x - offset
            contentRect.origin.y = lastWindow.frame.origin.y - offset
        }

        // Create a standard window (or utility) that holds the tabbed view
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable,],
            backing: .buffered,
            defer: false
        )
        
        if windows.isEmpty {
            window.center()
        }

        window.title = "Mira - Window \(windows.count + 1)"
        
        // Fix background visibility
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        
        // Fix desktop switching behavior - allow window to be visible across all spaces
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false // Explicitly managed by us
        
        applyLevel(to: window)

        let engine = CaptureEngine()
        engines[window] = engine
        
        let contentView = SingleMonitorView(windowManager: self, engine: engine)
        window.contentView = NSHostingView(rootView: contentView)
        
        // Set delegate to track window closure
        window.delegate = self
        
        window.makeKeyAndOrderFront(nil)
        
        // Ensure app can activate and receive focus
        NSApp.activate(ignoringOtherApps: true)
        
        windows.append(window)
    }

    func updateLevels() {
        let level: NSWindow.Level = Preferences.shared.isAlwaysOnTop ? .floating : .normal
        for window in windows {
            window.level = level
        }
    }
    
    private func applyLevel(to window: NSWindow) {
        window.level = Preferences.shared.isAlwaysOnTop ? .floating : .normal
    }
    
    func stop() {
        isStopping = true
        for window in windows {
            engines[window]?.stopCapture()
            window.close()
        }
        windows.removeAll()
        engines.removeAll()
    }
}

// MARK: - NSWindowDelegate
extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            print("Mira: Window '\(window.title)' closing. Current count: \(windows.count)")
            engines[window]?.stopCapture()
            engines.removeValue(forKey: window)
            windows.removeAll { $0 == window }
            print("Mira: After removal, tracked windows: \(windows.count), NSApp windows: \(NSApp.windows.count)")
        }
    }
}
