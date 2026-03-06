import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager: WindowManager!
    var menuBarManager: MenuBarManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMainMenu()

        windowManager = WindowManager()
        windowManager.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.menuBarManager = MenuBarManager(windowManager: self.windowManager)
        }
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit Mira", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(withTitle: "New Window", action: #selector(newWindowAction), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        NSApp.mainMenu = mainMenu
    }

    @objc func newWindowAction() {
        windowManager?.createNewWindow()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        windowManager?.stop()
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowManager?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct MonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
