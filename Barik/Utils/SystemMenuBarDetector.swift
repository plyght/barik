import Foundation
import SwiftUI
import Combine

class SystemMenuBarDetector: ObservableObject {
    @Published var isSystemMenuBarVisible: Bool = false
    
    private var mouseTracker: Any?
    private var timer: Timer?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        // Monitor mouse position globally
        mouseTracker = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.checkMousePosition(event.locationInWindow)
        }
        
        // Also check periodically for system menu bar windows
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkSystemMenuBar()
        }
    }
    
    private func stopMonitoring() {
        if let tracker = mouseTracker {
            NSEvent.removeMonitor(tracker)
            mouseTracker = nil
        }
        timer?.invalidate()
        timer = nil
    }
    
    private func checkMousePosition(_ location: CGPoint) {
        guard let screen = NSScreen.main else { return }
        
        // Convert to screen coordinates
        let mouseY = screen.frame.height - location.y
        let isAtTop = mouseY >= screen.frame.height - 5 // Within 5 pixels of top
        
        if isAtTop {
            checkSystemMenuBar()
        }
    }
    
    private func checkSystemMenuBar() {
        let wasVisible = isSystemMenuBarVisible
        let newVisibility = isSystemMenuBarCurrentlyVisible()
        
        if wasVisible != newVisibility {
            DispatchQueue.main.async {
                self.isSystemMenuBarVisible = newVisibility
            }
        }
    }
    
    private func isSystemMenuBarCurrentlyVisible() -> Bool {
        // Check if there are system menu bar related windows visible
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
        
        for window in windowList {
            guard let name = window[kCGWindowName as String] as? String,
                  let layer = window[kCGWindowLayer as String] as? Int,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let y = bounds["Y"] as? CGFloat else { continue }
            
            // Check for system menu bar windows at the top of the screen
            if (name.contains("Menu") || name.contains("menubar") || layer == 25) && y <= 5 {
                return true
            }
        }
        
        // Also check mouse position as backup
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return false }
        
        // If mouse is at very top, assume menu bar might be showing
        let screenHeight = screen.frame.height
        return mouseLocation.y >= screenHeight - 2
    }
}
