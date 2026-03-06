import SwiftUI

class Preferences: ObservableObject {
    static let shared = Preferences()
    static let allScreensID = -1 // Special ID for "All Screens" view
    
    @AppStorage("isAlwaysOnTop") var isAlwaysOnTop: Bool = false
    @AppStorage("selectedDisplayID") var selectedDisplayID: Int = 0 
    @AppStorage("isLaunchAtLoginEnabled") var isLaunchAtLoginEnabled: Bool = false
}
