import Foundation
import SwiftUI
import Combine

class SystemMenuBarDetector: ObservableObject {
    @Published var isSystemMenuBarVisible: Bool = false
    
    private var mouseTracker: Any?
    private var timer: Timer?
    private var lastMouseY: CGFloat = 0
    
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
        
        // Lightweight periodic check
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.periodicCheck()
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
        
        let mouseY = screen.frame.height - location.y
        let hideThreshold = screen.frame.height - 3    // Hide when within 3px of top
        let showThreshold = screen.frame.height - 50   // Show when 50px+ from top
        
        // Avoid redundant checks if mouse hasn't moved much
        if abs(mouseY - lastMouseY) < 1 {
            return
        }
        lastMouseY = mouseY
        
        if mouseY >= hideThreshold && !isSystemMenuBarVisible {
            // Mouse at top and barik visible -> hide barik
            checkSystemMenuBar()
        } else if mouseY < showThreshold && isSystemMenuBarVisible {
            // Mouse far enough from top and barik hidden -> show barik
            DispatchQueue.main.async {
                self.isSystemMenuBarVisible = false
            }
        }
    }
    
    private func periodicCheck() {
        // Only do expensive checks if we think system menu bar should be visible
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return }
        
        let screenHeight = screen.frame.height
        let hideThreshold = screenHeight - 3
        let showThreshold = screenHeight - 50
        
        if mouseLocation.y >= hideThreshold && !isSystemMenuBarVisible {
            checkSystemMenuBar()
        } else if mouseLocation.y < showThreshold && isSystemMenuBarVisible {
            DispatchQueue.main.async {
                self.isSystemMenuBarVisible = false
            }
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
