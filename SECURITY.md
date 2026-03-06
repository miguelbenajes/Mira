# Security Policy

**Mira — Monitor Float Application**
**Last Updated:** March 2026

---

## Security Model

Mira is designed with a minimal attack surface. It has no network code, no data persistence, and relies entirely on macOS's built-in permission system for screen capture access.

## Security Features

### 1. No Network Access

Mira contains **zero networking code**. It cannot:
- Make HTTP/HTTPS requests
- Open sockets
- Connect to any server, API, or cloud service
- Transmit data in any form

This is verifiable by auditing the source code — no `URLSession`, `Network.framework`, or socket imports exist.

### 2. macOS Permission Gating

Screen capture access is controlled by macOS TCC (Transparency, Consent, and Control):
- The user must explicitly grant Screen Recording permission in System Settings
- macOS shows a system-level dialog — Mira cannot bypass this
- Permission can be revoked at any time
- Revoking permission immediately stops all capture

### 3. No Data Persistence

- Screen frames exist only in memory as `CGImage` objects
- Each new frame replaces the previous one — no frame buffer history
- When capture stops, all image data is released
- No screenshots, recordings, or logs are saved to disk

### 4. Process Isolation

- Runs as an LSUIElement agent app (no Dock presence)
- Each capture window has its own independent `CaptureEngine` instance
- Closing a window immediately stops its associated capture stream

### 5. Ad-Hoc Code Signing

- The build script signs the app with `codesign --force --deep --sign -`
- Prevents "damaged app" errors on other Macs
- The signature can be verified: `codesign --verify --verbose Mira.app`

## What Mira CANNOT Do

| Action | Possible? |
|---|---|
| Record screen to a file | No |
| Save screenshots | No |
| Transmit captured frames | No — no network code |
| Access files on disk | No — only its own preferences |
| Run hidden in the background | No — always shows a menu bar icon |
| Access camera or microphone | No — no entitlements requested |
| Bypass macOS Screen Recording permission | No — enforced by the OS kernel |
| Capture without the user knowing | No — requires explicit permission grant |

## Known Security Considerations

### Screen Recording Permission Scope

macOS Screen Recording permission grants access to **all display content**, including:
- Other application windows
- Password fields (though macOS may mask these)
- Notification content
- Desktop and menu bar

**Users should be aware** that granting this permission allows Mira to see everything on the captured display. This is inherent to any screen capture application.

### Unsigned / Ad-Hoc Signed Distribution

Mira is distributed without Apple notarization. This means:
- macOS Gatekeeper will show a warning on first launch
- Users must right-click > Open to bypass the warning
- The app is ad-hoc signed to prevent "damaged app" errors
- For maximum security, users should build from source and verify the code

## Supported Versions

| Version | Supported |
|---|---|
| 1.0.x | Yes |

## Reporting Security Issues

If you discover a security vulnerability in Mira:

1. **Do not** open a public GitHub issue
2. Contact the maintainer privately through GitHub
3. Include a description of the vulnerability and steps to reproduce
4. Allow reasonable time for a fix before public disclosure

## Verification

You can verify Mira's security claims by:

1. **Auditing the source code** — it's fully open source
2. **Checking network activity** — use Little Snitch or `lsof -i` while Mira is running (you'll see zero connections)
3. **Monitoring file system** — use `fs_usage` to confirm no file writes during capture
4. **Verifying the signature** — `codesign --verify --verbose /Applications/Mira.app`

---

**Summary: Mira has no network code, no data storage, no file access, and relies on macOS's own permission system. It's auditable, open source, and minimal by design.**
