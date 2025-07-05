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
        menu.addItem(NSMenuItem(title: "Expand Left (⌘+⌥+←)", action: #selector(resizeWindowLeft), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Expand Right (⌘+⌥+→)", action: #selector(resizeWindowRight), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func registerHotkey() {
        // Register global hotkeys using Carbon API for better reliability
        let signature = OSType(0x57696E64) // 'Wind'
        let modifierFlags: UInt32 = UInt32(cmdKey + optionKey)
        
        // Register Cmd+Opt+Left Arrow
        registerSingleHotkey(keyCode: 123, hotKeyId: 2, signature: signature, modifierFlags: modifierFlags)
        
        // Register Cmd+Opt+Right Arrow
        registerSingleHotkey(keyCode: 124, hotKeyId: 3, signature: signature, modifierFlags: modifierFlags)
        
        installEventHandler()
    }
    
    private func registerSingleHotkey(keyCode: UInt32, hotKeyId: UInt32, signature: OSType, modifierFlags: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: hotKeyId)
        
        let status = RegisterEventHotKey(keyCode, modifierFlags, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            print("Hotkey \(hotKeyId) registered successfully")
        } else {
            print("Failed to register hotkey \(hotKeyId): \(status)")
        }
    }
    
    private func installEventHandler() {
        let eventTypes = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))]
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(theEvent, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if status == noErr {
                DispatchQueue.main.async {
                    let appDelegate = NSApplication.shared.delegate as! AppDelegate
                    
                    switch hotKeyID.id {
                    case 2: // Cmd+Opt+Left Arrow
                        appDelegate.resizeWindowLeft()
                    case 3: // Cmd+Opt+Right Arrow
                        appDelegate.resizeWindowRight()
                    default:
                        break
                    }
                }
            }
            
            return noErr
        }, 1, eventTypes, nil, nil)
    }
    
    @objc private func resizeWindowLeft() {
        WindowManager.shared.resizeWindowLeft()
    }
    
    @objc private func resizeWindowRight() {
        WindowManager.shared.resizeWindowRight()
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