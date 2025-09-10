import Foundation
import SwiftUI
import Combine

class FocusedAppManager: ObservableObject {
    @Published var focusedAppName: String = ""
    @Published var focusedAppIcon: NSImage?
    
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        updateFocusedApp()
        
        // Update every 0.5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateFocusedApp()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateFocusedApp() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            focusedAppName = ""
            focusedAppIcon = nil
            return
        }
        
        let newAppName = frontApp.localizedName ?? "Unknown"
        
        // Only update if the app changed to avoid unnecessary UI updates
        if newAppName != focusedAppName {
            DispatchQueue.main.async {
                self.focusedAppName = newAppName
                self.focusedAppIcon = frontApp.icon
            }
        }
    }
}
