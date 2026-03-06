import SwiftUI
import AppKit
import ServiceManagement
import Combine

class MenuBarManager: NSObject {
    var statusItem: NSStatusItem!
    weak var windowManager: WindowManager?
    var aboutWindow: NSWindow?
    var legalWindow: NSWindow?
    
    // Observation tokens
    private var preferencesObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    init(windowManager: WindowManager) {
        self.windowManager = windowManager
        super.init()
        setupMenuBar()
        setupObservers()
    }
    
    func setupObservers() {
        // Observe UserDefaults changes to update menu state
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMenu()
        }
        
        // Observe windows changes
        windowManager?.$windows
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Using a system symbol looking like an "Eye" for "Mira" / "SecondSight" concept
            // "eye" or "eye.circle" are good candidates.
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Mira")
        }
        
        updateMenu()
    }
    
    func updateMenu() {
        let menu = NSMenu()
        
        // App Name / Header
        let titleItem = NSMenuItem(title: "Mira", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // Window Management Section
        let bringAllItem = NSMenuItem(title: "Bring All to Front", action: #selector(bringAllToFront), keyEquivalent: "")
        bringAllItem.target = self
        menu.addItem(bringAllItem)
        
        // Dynamic Window List
        if let wm = windowManager, !wm.windows.isEmpty {
            let windowsMenu = NSMenu()
            let windowsItem = NSMenuItem(title: "Open Windows", action: nil, keyEquivalent: "")
            windowsItem.submenu = windowsMenu
            
            for (index, window) in wm.windows.enumerated() {
                let winItem = NSMenuItem(title: window.title.isEmpty ? "Window \(index + 1)" : window.title, action: #selector(focusWindow(_:)), keyEquivalent: "")
                winItem.target = self
                winItem.representedObject = window
                windowsMenu.addItem(winItem)
            }
            menu.addItem(windowsItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Always on Top
        let aotItem = NSMenuItem(title: "Always on Top", action: #selector(toggleAlwaysOnTop), keyEquivalent: "")
        aotItem.target = self
        aotItem.state = Preferences.shared.isAlwaysOnTop ? .on : .off
        menu.addItem(aotItem)
        
        // Launch at Login
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = Preferences.shared.isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(loginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Monitors list (Informational or switching)
        if let wm = windowManager {
            let screensHeader = NSMenuItem(title: "New Window from Monitor:", action: nil, keyEquivalent: "")
            screensHeader.isEnabled = false
            menu.addItem(screensHeader)
            
            if wm.availableScreens.isEmpty {
                 let noMonItem = NSMenuItem(title: "None (Internal only)", action: nil, keyEquivalent: "")
                 noMonItem.isEnabled = false
                 menu.addItem(noMonItem)
            } else {
                // Add "All Screens" option
                let allScreensItem = NSMenuItem(title: "  All Screens", action: #selector(selectMonitor(_:)), keyEquivalent: "")
                allScreensItem.tag = Preferences.allScreensID
                allScreensItem.target = self
                menu.addItem(allScreensItem)
                
                // Individual screens
                for screenId in wm.availableScreens {
                    let name = wm.screenName(for: screenId)
                    let item = NSMenuItem(title: "  " + name, action: #selector(selectMonitor(_:)), keyEquivalent: "")
                    item.tag = screenId
                    item.target = self
                    menu.addItem(item)
                }
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // New Window
        let newWindowItem = NSMenuItem(title: "New Window", action: #selector(createNewWindow), keyEquivalent: "n")
        newWindowItem.target = self
        menu.addItem(newWindowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // About Mira
        let aboutItem = NSMenuItem(title: "About Mira", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // Legal Information
        let legalItem = NSMenuItem(title: "Legal Information", action: #selector(showLegal), keyEquivalent: "")
        legalItem.target = self
        menu.addItem(legalItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Mira", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func focusWindow(_ sender: NSMenuItem) {
        if let window = sender.representedObject as? NSWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func bringAllToFront() {
        windowManager?.windows.forEach { $0.makeKeyAndOrderFront(nil) }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func toggleLaunchAtLogin() {
        Preferences.shared.isLaunchAtLoginEnabled.toggle()
        let service = SMAppService.mainApp
        do {
            if Preferences.shared.isLaunchAtLoginEnabled {
                try service.register()
            } else {
                try service.unregister()
            }
            print("Mira: Launch at Login set to \(Preferences.shared.isLaunchAtLoginEnabled)")
        } catch {
            print("Mira: Failed to toggle Launch at Login: \(error)")
        }
        updateMenu()
    }
    
    @objc func toggleAlwaysOnTop() {
        Preferences.shared.isAlwaysOnTop.toggle()
        windowManager?.updateLevels()
        updateMenu()
    }
    
    @objc func selectMonitor(_ sender: NSMenuItem) {
        Preferences.shared.selectedDisplayID = sender.tag
        updateMenu()
    }
    
    @objc func createNewWindow() {
        windowManager?.createNewWindow()
    }
    
    @objc func showAbout() {
        // If window already exists, bring it to front
        if let window = aboutWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new About window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About Mira"
        window.center()
        window.contentView = NSHostingView(rootView: AboutView())
        window.isReleasedWhenClosed = false // We manage it
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        
        self.aboutWindow = window
    }
    
    @objc func showLegal() {
        if let window = legalWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Mira Legal Information"
        window.center()
        window.contentView = NSHostingView(rootView: LegalView())
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
        self.legalWindow = window
    }
    
    @objc func quitApp() {
        windowManager?.stop()
        NSApplication.shared.terminate(nil)
    }
}
