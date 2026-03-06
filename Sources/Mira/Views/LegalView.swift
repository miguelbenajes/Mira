import SwiftUI

struct LegalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                LegalContentView(title: "License", content: licenseText)
                    .tabItem { Text("License") }
                
                LegalContentView(title: "Privacy Policy", content: privacyText)
                    .tabItem { Text("Privacy") }
                
                LegalContentView(title: "Security Policy", content: securityText)
                    .tabItem { Text("Security") }
            }
            .padding()
            
            Divider()
            
            HStack {
                Spacer()
                Button("OK") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 500, height: 600)
    }
}

struct LegalContentView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
            }
        }
        .padding()
    }
}

// Content strings
private let licenseText = """
MIT License

Copyright (c) 2026 Miguel Angel Benajes

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

SECURITY AND PRIVACY NOTICE:

This software requires Screen Recording permissions to function. Users must:
1. Explicitly grant Screen Recording permission through macOS System Settings
2. Understand that this permission allows the application to capture screen content
3. Use this software responsibly and in compliance with all applicable laws
4. Not use this software to capture, record, or transmit sensitive, private, or 
   confidential information without proper authorization

The developers of this software:
- Do NOT collect, store, or transmit any screen capture data
- Do NOT include any network functionality for data transmission
- Are NOT responsible for misuse of this software by end users
- Recommend users review their local privacy laws before use

By using this software, you agree to use it ethically and legally, respecting
the privacy and rights of all individuals whose screens may be captured.
"""

private let privacyText = """
Privacy Policy for Mira
Last Updated: February 12, 2026

Mira is a local-only screen monitoring application for macOS that displays external monitor content in floating windows.

Data Collection
Mira does NOT collect, store, or transmit any data. Specifically:
- No network connections: The application has no networking code
- No analytics: No usage tracking or telemetry
- No cloud services: All processing happens locally on your device
- No data storage: Screen captures are displayed in real-time only and never saved to disk
- No third-party services: No external dependencies that could collect data

Permissions Required
Mira requires macOS Screen Recording permission to capture and display monitor content. This permission:
- Is requested explicitly by macOS when you first run the app
- Can be revoked at any time in System Settings
- Only allows the app to capture screen content while running
- Does not grant access to any other system resources

Your Data Rights
Since Mira does not collect any data, there is no user data to access, modify, delete, or export.

Security Measures
- All screen capture happens in-memory only
- No persistent storage of captured content
- No network transmission capabilities

Responsible Use
Users are responsible for complying with local privacy laws and obtaining necessary consent before capturing others' screens.
"""

private let securityText = """
Security Policy

Security Features:
1. No Network Access: Mira has zero networking code - it cannot transmit data anywhere
2. macOS Sandboxing: Relies on macOS permission system for screen recording access
3. Local Processing Only: All screen capture and rendering happens locally
4. No Data Persistence: Screen captures are never written to disk

What Mira CANNOT Do:
- record or save screen captures to files
- transmit data over network
- access files outside its sandbox
- run in background without user knowledge
- bypass macOS permission requirements
- access camera, microphone, or other sensors

Reporting Security Issues:
If you discover a security vulnerability, please contact the maintainers privately.

Version: 1.0  
Last Updated: February 12, 2026
"""
