import SwiftUI

struct AllScreensView: View {
    @ObservedObject var windowManager: WindowManager
    
    var body: some View {
        GeometryReader { geometry in
            let screens = windowManager.availableScreens.compactMap { windowManager.getScreen(by: $0) }
            
            if screens.isEmpty {
                Text("No screens available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Calculate grid layout
                let columns = screens.count <= 2 ? screens.count : 2
                let gridItems = Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
                
                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 8) {
                        ForEach(screens, id: \.self) { screen in
                            ModernPreviewGridItem(screen: screen, windowManager: windowManager, totalCount: screens.count, geometry: geometry)
                        }
                    }
                    .padding(8)
                }
            }
        }
    }
}

/// A wrapper that manages a dedicated CaptureEngine for the grid view
struct ModernPreviewGridItem: View {
    let screen: NSScreen
    @ObservedObject var windowManager: WindowManager
    let totalCount: Int
    let geometry: GeometryProxy
    
    @StateObject private var engine = CaptureEngine()
    
    var body: some View {
        VStack(spacing: 4) {
            MonitorPreview(screen: screen, windowManager: windowManager, engine: engine)
                .frame(height: geometry.size.height / CGFloat(totalCount <= 2 ? 1 : 2) - 40)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .task {
                    if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
                        await engine.startCapture(displayID: screenNumber.uint32Value)
                    }
                }
            
            Text(screen.localizedName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
