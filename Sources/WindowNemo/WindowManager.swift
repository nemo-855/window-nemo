import Cocoa
import ApplicationServices

enum WindowPosition {
    case left
    case center
    case right
    case leftTwoThirds
    case rightTwoThirds
    case fullscreen
}

class WindowManager {
    static let shared = WindowManager()
    
    private var windowStates: [String: WindowPosition] = [:]
    
    private init() {}
    
    
    func resizeWindowLeft() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost application found")
            return
        }
        
        let pid = frontmostApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)
        
        guard result == .success, let window = windowRef else {
            print("Failed to get focused window")
            return
        }
        
        let windowKey = getWindowKey(window: window as! AXUIElement)
        progressWindowLeft(window: window as! AXUIElement, windowKey: windowKey)
    }
    
    func resizeWindowRight() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost application found")
            return
        }
        
        let pid = frontmostApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)
        
        guard result == .success, let window = windowRef else {
            print("Failed to get focused window")
            return
        }
        
        let windowKey = getWindowKey(window: window as! AXUIElement)
        progressWindowRight(window: window as! AXUIElement, windowKey: windowKey)
    }
    
    private func getWindowKey(window: AXUIElement) -> String {
        var titleRef: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        
        let title = (titleResult == .success && titleRef != nil) ? (titleRef as! String) : "Unknown"
        
        var positionRef: CFTypeRef?
        let positionResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        
        let positionKey = (positionResult == .success && positionRef != nil) ? String(describing: positionRef!) : "Unknown"
        
        return "\(title)_\(positionKey)"
    }
    
    
    private func progressWindowLeft(window: AXUIElement, windowKey: String) {
        let currentPosition = getCurrentWindowPosition(window: window)
        
        let nextPosition: WindowPosition
        switch currentPosition {
        case .left:
            nextPosition = .leftTwoThirds
        case .leftTwoThirds:
            nextPosition = .fullscreen
        default:
            nextPosition = .left
        }
        
        windowStates[windowKey] = nextPosition
        resizeWindow(window, position: nextPosition)
    }
    
    private func progressWindowRight(window: AXUIElement, windowKey: String) {
        let currentPosition = getCurrentWindowPosition(window: window)
        
        let nextPosition: WindowPosition
        switch currentPosition {
        case .right:
            nextPosition = .rightTwoThirds
        case .rightTwoThirds:
            nextPosition = .fullscreen
        default:
            nextPosition = .right
        }
        
        windowStates[windowKey] = nextPosition
        resizeWindow(window, position: nextPosition)
    }
    
    private func getCurrentWindowPosition(window: AXUIElement) -> WindowPosition {
        guard let screen = NSScreen.main else { return .left }
        
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        let positionResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        
        guard positionResult == .success, sizeResult == .success,
              let positionValue = positionRef, let sizeValue = sizeRef else {
            return .left
        }
        
        var position = CGPoint.zero
        var size = CGSize.zero
        
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        
        let screenFrame = screen.visibleFrame
        let oneThird = screenFrame.width / 3
        let twoThirds = screenFrame.width * 2 / 3
        
        if size.width >= screenFrame.width * 0.95 {
            return .fullscreen
        } else if size.width >= twoThirds * 0.95 {
            if position.x <= screenFrame.origin.x + 10 {
                return .leftTwoThirds
            } else {
                return .rightTwoThirds
            }
        } else if size.width >= oneThird * 0.95 {
            if position.x <= screenFrame.origin.x + 10 {
                return .left
            } else if position.x >= screenFrame.origin.x + twoThirds - 10 {
                return .right
            } else {
                return .center
            }
        }
        
        return .left
    }
    
    private func resizeWindow(_ window: AXUIElement, position: WindowPosition) {
        guard let screen = NSScreen.main else {
            print("No main screen found")
            return
        }
        
        let fullScreenFrame = screen.frame
        let oneThird = fullScreenFrame.width / 3
        let twoThirds = fullScreenFrame.width * 2 / 3
        let fullHeight = fullScreenFrame.height
        
        let newPosition: CGPoint
        let newSize: CGSize
        
        switch position {
        case .left:
            newPosition = CGPoint(x: fullScreenFrame.origin.x, y: fullScreenFrame.origin.y)
            newSize = CGSize(width: oneThird, height: fullHeight)
        case .center:
            newPosition = CGPoint(x: fullScreenFrame.origin.x + oneThird, y: fullScreenFrame.origin.y)
            newSize = CGSize(width: oneThird, height: fullHeight)
        case .right:
            newPosition = CGPoint(x: fullScreenFrame.origin.x + twoThirds, y: fullScreenFrame.origin.y)
            newSize = CGSize(width: oneThird, height: fullHeight)
        case .leftTwoThirds:
            newPosition = CGPoint(x: fullScreenFrame.origin.x, y: fullScreenFrame.origin.y)
            newSize = CGSize(width: twoThirds, height: fullHeight)
        case .rightTwoThirds:
            newPosition = CGPoint(x: fullScreenFrame.origin.x + oneThird, y: fullScreenFrame.origin.y)
            newSize = CGSize(width: twoThirds, height: fullHeight)
        case .fullscreen:
            newPosition = CGPoint(x: fullScreenFrame.origin.x, y: fullScreenFrame.origin.y)
            newSize = CGSize(width: fullScreenFrame.width, height: fullHeight)
        }
        
        setWindowPosition(window, position: newPosition)
        setWindowSize(window, size: newSize)
        
        print("Window resized to \(position) position")
    }
    
    private func setWindowPosition(_ window: AXUIElement, position: CGPoint) {
        var mutablePosition = position
        let positionValue = AXValueCreate(AXValueType.cgPoint, &mutablePosition)
        if let positionValue = positionValue {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
    }
    
    private func setWindowSize(_ window: AXUIElement, size: CGSize) {
        var mutableSize = size
        let sizeValue = AXValueCreate(AXValueType.cgSize, &mutableSize)
        if let sizeValue = sizeValue {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
    }
}