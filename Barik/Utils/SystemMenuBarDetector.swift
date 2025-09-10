import Foundation
import SwiftUI
import Combine

class SystemMenuBarDetector: ObservableObject {
    static let shared = SystemMenuBarDetector()
    @Published var isSystemMenuBarVisible: Bool = false
    
    private var timer: Timer?
    private var lastMouseY: CGFloat = -1
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMousePosition()
        }
    }
    
    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkMousePosition() {
        let mouseLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return }
        
        let screenHeight = screen.frame.height
        let hideThreshold = screenHeight - 5    // Hide when within 5px of top
        let showThreshold = screenHeight - 30   // Show when 30px+ from top
        
        // Skip if mouse hasn't moved significantly
        if abs(mouseLocation.y - lastMouseY) < 1 {
            return
        }
        lastMouseY = mouseLocation.y
        
        let shouldHide = mouseLocation.y >= hideThreshold
        let shouldShow = mouseLocation.y < showThreshold
        
        if shouldHide && !isSystemMenuBarVisible {
            DispatchQueue.main.async {
                self.isSystemMenuBarVisible = true
            }
        } else if shouldShow && isSystemMenuBarVisible {
            DispatchQueue.main.async {
                self.isSystemMenuBarVisible = false
            }
        }
    }
}
