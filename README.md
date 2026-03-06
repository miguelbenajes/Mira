# Mira

**A macOS menu bar application that displays external monitors in real-time floating windows.**

Developed by **Miguel Angel Benajes**

---

## What is Mira?

Mira captures your external displays using Apple's ScreenCaptureKit and renders them in resizable, always-on-top floating windows. It runs entirely from the menu bar (no Dock icon) and is designed to be lightweight and privacy-first.

**Use cases:**
- Keep an eye on a presentation running on an external display
- Monitor a secondary screen without physically turning your head
- View all connected monitors simultaneously in a grid layout

## Features

- **Real-time screen capture** at 60 FPS using ScreenCaptureKit (SCK)
- **Multi-window support** — open as many monitor windows as you need
- **All Screens view** — see all connected monitors simultaneously in a grid
- **Always on Top** — keep windows floating above all other applications
- **Per-window monitor selection** — each window can show a different display
- **Resizable to tiny sizes** — minimum 100x80 pixels for a compact preview
- **Launch at Login** — start Mira automatically via macOS ServiceManagement
- **Menu bar controls** — eye icon with full dropdown menu for all features
- **In-window controls** — gear menu overlay for quick monitor switching
- **Screen hotplug detection** — automatically updates when monitors are connected/disconnected
- **Keyboard shortcuts** — Cmd+Q quit, Cmd+W close window, Cmd+N new window
- **No data collection** — zero network code, all processing is local
- **Ad-hoc code signed** — works on other Macs without a Developer ID

## Requirements

- **macOS 13.0** (Ventura) or later
- **Xcode Command Line Tools** (for building from source)
- **Screen Recording permission** (requested on first launch)

## Installation

### Option 1: DMG Installer (Recommended)

1. Download `Mira_Installer.dmg` from Releases
2. Open the DMG and drag **Mira** to **Applications**
3. **Right-click Mira in Applications > Open** (required for unsigned/ad-hoc signed apps on first launch)
4. Grant Screen Recording permission when prompted
5. The eye icon appears in your menu bar — you're ready

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/miguelbenajes/Mira.git
cd Mira

# Build release binary
swift build -c release

# Create the .app bundle (includes ad-hoc code signing)
./bundle_app.sh

# Or create the full DMG installer
./create_installer.sh
```

### If macOS says "Mira is damaged"

This should not happen with the ad-hoc signed build, but if it does:

```bash
xattr -cr /Applications/Mira.app
```

Then right-click > Open again.

## Screen Recording Permission

Mira requires macOS Screen Recording permission to capture display content. Here's how it works:

1. **First launch**: macOS shows a system dialog asking to allow or deny screen capture
2. **If you click Allow**: Capture starts immediately
3. **If you click Deny or need to grant later**: The capture window shows an inline guide with an "Open Settings" button
4. **After granting in System Settings**: macOS may ask you to "Quit & Reopen" — click it, and Mira will restart with capture working
5. **Auto-retry**: Mira silently checks every 4 seconds if permission was granted (using `CGPreflightScreenCaptureAccess` to avoid triggering additional system dialogs)

You can revoke this permission anytime in **System Settings > Privacy & Security > Screen Recording**.

## Usage

### Menu Bar

Click the **eye icon** in the menu bar to access:

| Menu Item | Description |
|---|---|
| **Bring All to Front** | Shows all Mira windows above other apps |
| **Open Windows** | Submenu listing all open Mira windows — click to focus |
| **Always on Top** | Toggle floating window level (persisted) |
| **Launch at Login** | Toggle auto-start on login (uses SMAppService) |
| **New Window from Monitor** | Open a new window capturing a specific display |
| **All Screens** | Open a new window showing all monitors in a grid |
| **New Window** | Open a new capture window (Cmd+N) |
| **About Mira** | Version and copyright information |
| **Legal Information** | License, Privacy Policy, Security Policy |
| **Quit Mira** | Quit the application (Cmd+Q) |

### In-Window Controls

Each capture window has an overlay in the top-right corner:

- **[ + ] button** — Create a new window
- **Gear menu** — Select which monitor to display, toggle Always on Top, or quit

### Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+Q` | Quit Mira entirely |
| `Cmd+W` | Close the current window (app stays in menu bar) |
| `Cmd+N` | Open a new capture window |

## Architecture

Mira is a Swift Package Manager project using SwiftUI and AppKit. It runs as an LSUIElement agent app (menu bar only, no Dock icon).

### Project Structure

```
Mira/
├── Package.swift                    # SPM manifest — macOS 13+, single executable target
├── Sources/
│   └── Mira/
│       ├── MonitorApp.swift         # @main entry point + AppDelegate (lifecycle, menus)
│       ├── CaptureEngine.swift      # ScreenCaptureKit wrapper (SCStream, 60 FPS capture)
│       ├── WindowManager.swift      # NSWindow creation, tracking, and lifecycle
│       ├── MenuBarManager.swift     # NSStatusItem menu bar with full dropdown
│       ├── Preferences.swift        # Singleton with @AppStorage (always-on-top, display ID, login)
│       └── Views/
│           ├── SingleMonitorView.swift  # Main view — switches between single monitor and all screens
│           ├── AllScreensView.swift     # Grid layout showing all monitors simultaneously
│           ├── MonitorPreview.swift     # Renders CGImage frames + inline permission handling
│           ├── ControlsOverlay.swift    # Floating gear/plus button overlay on each window
│           ├── AboutView.swift          # About window content
│           └── LegalView.swift          # Tabbed legal info (License, Privacy, Security)
├── Assets/
│   ├── eye_logo.png                 # App icon source
│   ├── icon.psd                     # Icon Photoshop source
│   ├── dmg_background_corporate.png # DMG installer background
│   └── dmg_background_corporate.psd # DMG background Photoshop source
├── Mira.entitlements                # Entitlements for ad-hoc code signing
├── bundle_app.sh                    # Builds .app bundle with Info.plist, icon, and code signing
└── create_installer.sh              # Creates styled DMG installer with drag-to-Applications
```

### Component Details

#### `MonitorApp.swift` — Application Entry Point

- Uses `@NSApplicationDelegateAdaptor` to bridge SwiftUI App lifecycle with AppKit's `NSApplicationDelegate`
- Sets activation policy to `.accessory` (menu bar only, no Dock icon)
- Creates the main `NSMenu` with Quit (Cmd+Q), New Window (Cmd+N), and Close Window (Cmd+W)
- Initializes `WindowManager` and `MenuBarManager` on launch
- `applicationShouldTerminateAfterLastWindowClosed` returns `false` — closing all windows keeps the menu bar alive
- `applicationShouldTerminate` always returns `.terminateNow` — Cmd+Q and system termination (including macOS "Quit & Reopen" for permissions) work correctly

#### `CaptureEngine.swift` — Screen Capture

- Wraps Apple's `SCStream` (ScreenCaptureKit) to capture a single display
- Publishes `currentImage: CGImage?` at up to 60 FPS via `@Published` for SwiftUI observation
- Tracks capture state via `CaptureState` enum: `.idle`, `.capturing`, `.noPermission`, `.error(String)`
- Permission detection: catches SCK error code `-3801` (no permission) and sets `.noPermission` state
- Frame conversion: receives `CMSampleBuffer` via `SCStreamOutput`, converts to `CGImage` via `VTCreateCGImageFromCVPixelBuffer`
- Each window gets its own independent `CaptureEngine` instance

#### `WindowManager.swift` — Window Lifecycle

- Creates and tracks multiple `NSWindow` instances, each mapped to its own `CaptureEngine`
- Windows use `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]` — visible across all Spaces/desktops
- Cascades new window positions (20pt offset from the last window)
- Listens for `didChangeScreenParametersNotification` to detect monitor connect/disconnect
- Publishes `availableScreens: [Int]` (display IDs) for the monitor picker
- Implements `NSWindowDelegate` to clean up engines when windows are closed

#### `MenuBarManager.swift` — Menu Bar

- Creates an `NSStatusItem` with the SF Symbol "eye" icon
- Rebuilds the entire `NSMenu` on every state change (preferences, window list)
- Observes `UserDefaults.didChangeNotification` and `WindowManager.$windows` via Combine
- Launch at Login uses `SMAppService.mainApp.register()` / `.unregister()`
- Manages singleton About and Legal windows (reuses existing window if visible)

#### `Preferences.swift` — User Settings

- Singleton `Preferences.shared` with three `@AppStorage`-backed properties:
  - `isAlwaysOnTop: Bool` — window floating level
  - `selectedDisplayID: Int` — last selected display
  - `isLaunchAtLoginEnabled: Bool` — auto-start toggle
- `allScreensID = -1` — magic value for "All Screens" mode

#### `MonitorPreview.swift` — Capture Rendering + Permission UI

- Switches display based on `CaptureEngine.state`:
  - `.capturing` — renders `CGImage` with `.aspectRatio(contentMode: .fit)`
  - `.noPermission` — shows inline `PermissionInlineView` with "Open Settings" and "Retry" buttons
  - `.error` — shows error message with icon
  - `.idle` — shows loading spinner
- `PermissionInlineView` auto-retries every 4 seconds using `CGPreflightScreenCaptureAccess()` as a silent gate (avoids triggering system dialogs)

#### `SingleMonitorView.swift` — Main Content View

- Root view inside each `NSWindow`
- Switches between `MonitorPreview` (single monitor) and `AllScreensView` (grid) based on selected display ID
- Overlays `ControlsOverlay` (gear + plus buttons) on top
- Minimum frame size: 100x80 pixels

#### `AllScreensView.swift` — Multi-Monitor Grid

- Displays all connected monitors in a `LazyVGrid`
- Each grid item (`ModernPreviewGridItem`) creates its own `@StateObject CaptureEngine`
- Adaptive column count: 1-2 monitors = side by side, 3+ = 2-column grid

#### `ControlsOverlay.swift` — In-Window Controls

- Floating capsule-shaped overlay in the top-right corner
- **[ + ]** button to create a new window
- **Gear menu** with monitor picker (`Picker`), Always on Top toggle, and Quit button

### Build Scripts

#### `bundle_app.sh`

1. Runs `swift build -c release`
2. Creates `.app` bundle structure (`Contents/MacOS`, `Contents/Resources`)
3. Generates `Info.plist` with bundle ID `com.coyote.Mira`, `LSUIElement: true`, and `NSScreenCaptureUsageDescription`
4. Converts `eye_logo.png` to `.icns` via `sips` + `iconutil` (all standard macOS icon sizes)
5. Ad-hoc code signs with `codesign --force --deep --sign -` using `Mira.entitlements`
6. Strips quarantine attributes with `xattr -cr`
7. Verifies signature with `codesign --verify`

#### `create_installer.sh`

1. Calls `bundle_app.sh` to build the app
2. Creates a temporary DMG with the app + Applications symlink
3. Mounts and styles with AppleScript (icon positions, background image, icon size)
4. Converts to compressed final DMG (`UDZO`, zlib level 9)

## Privacy & Security

- **No network code** — Mira cannot transmit data anywhere
- **No data persistence** — screen captures exist only in memory, never written to disk
- **No analytics or telemetry** — zero tracking
- **Open source** — full source code available for audit
- **macOS permission gated** — requires explicit Screen Recording approval via System Settings
- **Permission revocable** — can be disabled anytime in System Settings > Privacy & Security > Screen Recording

## Troubleshooting

| Problem | Solution |
|---|---|
| **Black screen / "Initializing" forever** | Grant Screen Recording permission in System Settings > Privacy & Security > Screen Recording |
| **"Mira is damaged" on another Mac** | Run `xattr -cr /Applications/Mira.app` in Terminal, then right-click > Open |
| **App won't open at all** | Right-click > Open (required for non-notarized apps on first launch) |
| **Permission granted but still not capturing** | Toggle Screen Recording OFF then ON in System Settings, then click "Quit & Reopen" |
| **No monitors listed** | Connect an external display. Mira auto-detects screen changes |
| **Build fails** | Ensure Xcode CLI tools are installed: `xcode-select --install` |
| **Menu bar icon missing** | Mira may still be starting. Wait a moment or check Activity Monitor |

## License

MIT License — Copyright (c) 2026 Miguel Angel Benajes

See [Legal Information] in the app menu bar for full License, Privacy Policy, and Security Policy.

---

**Made by Miguel Angel Benajes** | Privacy-first, local-only, open source
