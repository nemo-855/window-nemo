import Cocoa
import ApplicationServices
import Carbon

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

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
            button.title = "⬜"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }
    
    @objc private func statusBarButtonClicked() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Resize Window (⌘+⌥+R)", action: #selector(resizeActiveWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func registerHotkey() {
        // Register global hotkey using Carbon API for better reliability
        let hotKeyId: UInt32 = 1
        let keyCode: UInt32 = 15 // R key
        let modifierFlags: UInt32 = UInt32(cmdKey + optionKey)
        
        var hotKeyRef: EventHotKeyRef?
        let signature = OSType(0x57696E64) // 'Wind'
        let hotKeyID = EventHotKeyID(signature: signature, id: hotKeyId)
        
        let status = RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            print("Hotkey registered successfully")
            installEventHandler()
        } else {
            print("Failed to register hotkey: \(status)")
        }
    }
    
    private func installEventHandler() {
        let eventTypes = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))]
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(theEvent, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if status == noErr && hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    let appDelegate = NSApplication.shared.delegate as! AppDelegate
                    appDelegate.resizeActiveWindow()
                }
            }
            
            return noErr
        }, 1, eventTypes, nil, nil)
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