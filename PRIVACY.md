# Privacy Policy

**Mira — Monitor Float Application**
**Last Updated:** March 2026

---

## Overview

Mira is a local-only macOS application that displays external monitor content in floating windows. This document describes how Mira handles (or rather, does not handle) your data.

## Data Collection

**Mira collects absolutely no data.** Specifically:

| Category | Status |
|---|---|
| Network connections | None — the app has zero networking code |
| Analytics / telemetry | None — no usage tracking of any kind |
| Cloud services | None — all processing is local |
| Data storage | None — screen captures exist only in memory |
| Third-party services | None — no external dependencies |
| Crash reporting | None — no crash data is collected or transmitted |

## Permissions Required

Mira requires a single macOS permission:

### Screen Recording

- **What it does**: Allows Mira to capture and display the content of your monitors in real-time floating windows
- **How it's requested**: macOS shows a system dialog on first launch; the user must explicitly grant access
- **How to revoke**: System Settings > Privacy & Security > Screen Recording > toggle Mira off
- **Scope**: Only active while the app is running; does not persist capture data

### What Mira does NOT request

- Camera access
- Microphone access
- Location access
- Contacts or calendar access
- File system access beyond its own sandbox
- Network/internet access
- Accessibility access

## Data Processing

All screen capture processing happens entirely on your local machine:

1. ScreenCaptureKit captures display frames as `CMSampleBuffer`
2. Frames are converted to `CGImage` in memory
3. SwiftUI renders the image in the window
4. Previous frames are released from memory immediately
5. No frames are ever written to disk or transmitted

## Your Data Rights

Since Mira does not collect any data, there is no user data to:
- Access
- Modify
- Export
- Delete
- Transfer

## Children's Privacy

Mira does not collect data from any users, including children.

## Changes to This Policy

Any changes to this privacy policy will be reflected in the app's source code repository and in the in-app Legal Information section.

## Contact

For privacy-related questions, please open an issue on the GitHub repository.

---

**Summary: Mira has no network code, collects no data, stores nothing, and sends nothing. Everything stays on your Mac.**
