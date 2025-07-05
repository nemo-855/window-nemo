import Cocoa
import ApplicationServices

class WindowManager {
    static let shared = WindowManager()
    
    private init() {}
    
    func resizeActiveWindow() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost application found")
            return
        }
        
        let pid = frontmostApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        var windowRef: AXUIElement?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)
        
        guard result == .success, let window = windowRef else {
            print("Failed to get focused window")
            return
        }
        
        resizeWindow(window)
    }
    
    private func resizeWindow(_ window: AXUIElement) {
        guard let screen = NSScreen.main else {
            print("No main screen found")
            return
        }
        
        let screenFrame = screen.visibleFrame
        let targetWidth = screenFrame.width / 3
        let targetHeight = screenFrame.height
        
        let newPosition = CGPoint(x: screenFrame.origin.x, y: screenFrame.origin.y)
        let newSize = CGSize(width: targetWidth, height: targetHeight)
        
        setWindowPosition(window, position: newPosition)
        setWindowSize(window, size: newSize)
        
        print("Window resized to 1/3 width, full height")
    }
    
    private func setWindowPosition(_ window: AXUIElement, position: CGPoint) {
        var positionValue = AXValueCreate(AXValueType.cgPoint, &position)
        if let positionValue = positionValue {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
    }
    
    private func setWindowSize(_ window: AXUIElement, size: CGSize) {
        var sizeValue = AXValueCreate(AXValueType.cgSize, &size)
        if let sizeValue = sizeValue {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }
}