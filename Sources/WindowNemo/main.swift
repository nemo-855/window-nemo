import Cocoa
import ApplicationServices

@main
struct WindowNemoApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        registerHotkey()
        requestAccessibilityPermission()
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "Window Nemo")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }
    
    @objc private func statusBarButtonClicked() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Resize Window (⌘+⌥+R)", action: #selector(resizeActiveWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.popUpMenu(menu)
    }
    
    private func registerHotkey() {
        let hotKeyCenter = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .option]) && event.keyCode == 15 { // Cmd+Opt+R
                self.resizeActiveWindow()
            }
        }
    }
    
    @objc private func resizeActiveWindow() {
        WindowManager.shared.resizeActiveWindow()
    }
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        if !AXIsProcessTrustedWithOptions(options as CFDictionary) {
            let alert = NSAlert()
            alert.messageText = "アクセシビリティ許可が必要です"
            alert.informativeText = "WindowNemoがウィンドウを操作するにはアクセシビリティ許可が必要です。システム環境設定で許可してください。"
            alert.runModal()
        }
    }
}