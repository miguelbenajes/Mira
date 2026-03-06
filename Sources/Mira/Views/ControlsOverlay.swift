import SwiftUI

struct ControlsOverlay: View {
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var preferences = Preferences.shared
    @Binding var selection: Int
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Spacer()
                
                HStack(spacing: 4) {
                    Button {
                        windowManager.createNewWindow()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                    }
                    .buttonStyle(.plain)

                    Menu {
                        // Monitor Selection
                        if !windowManager.availableScreens.isEmpty {
                            Picker("Select Monitor", selection: $selection) {
                                // All Screens option
                                Text("All Screens").tag(Preferences.allScreensID)
                                
                                Divider()
                                
                                // Individual screens
                                ForEach(windowManager.availableScreens, id: \.self) { screenId in
                                    Text(windowManager.screenName(for: screenId)).tag(screenId)
                                }
                            }
                            .pickerStyle(.inline)
                            
                            Divider()
                        }
                        
                        // Always on Top
                        Toggle("Always on Top", isOn: $preferences.isAlwaysOnTop)
                        
                        Divider()
                        
                        Button("Quit Mira") {
                            windowManager.stop()
                            NSApplication.shared.terminate(nil)
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(6)
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(4)
                .background(Color.gray.opacity(0.7))
                .clipShape(Capsule())
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            Spacer()
        }
    }
}
