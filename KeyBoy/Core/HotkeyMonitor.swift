import Foundation
import Carbon
import AppKit
import ApplicationServices

class HotkeyMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var configurationManager: ConfigurationManager
    private var shortcuts: [String: String] = [:]
    private var retryTimer: Timer?
    private var rightCmdPressed: Bool = false
    private var leftCmdPressed: Bool = false
    
    // Key codes for CMD keys
    private let kLeftCmdKeyCode: Int = 55
    private let kRightCmdKeyCode: Int = 54
    
    init(configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
        
        configurationManager.onConfigurationChanged = { [weak self] newShortcuts in
            self?.shortcuts = newShortcuts
            print("🔧 HotkeyMonitor updated with \(newShortcuts.count) shortcuts:")
            for (key, app) in newShortcuts.sorted(by: { $0.key < $1.key }) {
                print("   \(key) → \(app)")
            }
        }
    }
    
    func startMonitoring() {
        guard eventTap == nil else { return }
        
        // Monitor both key down and flags changed events to detect CMD keys
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        // Try to create event tap - this is the real permission test
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                
                if monitor.handleEvent(event, type: type) {
                    return nil
                } else {
                    return Unmanaged.passUnretained(event)
                }
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("❌ Failed to create event tap - accessibility permissions not granted or not yet active.")
            print("   Please ensure KeyBoy is enabled in System Preferences > Privacy & Security > Accessibility")
            print("   Retrying in 3 seconds...")
            scheduleRetry()
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        guard let runLoopSource = runLoopSource else {
            print("❌ Failed to create run loop source")
            stopMonitoring()
            return
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        // Cancel retry timer if we succeeded
        retryTimer?.invalidate()
        retryTimer = nil
        
        print("✅ KeyBoy hotkey monitoring started successfully!")
        print("🔥 Try using Right CMD + K, A, S, C, or Z")
    }
    
    func stopMonitoring() {
        retryTimer?.invalidate()
        retryTimer = nil
        
        guard let eventTap = eventTap else { return }
        
        CGEvent.tapEnable(tap: eventTap, enable: false)
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        CFMachPortInvalidate(eventTap)
        self.eventTap = nil
        self.runLoopSource = nil
        
        print("HotkeyMonitor stopped")
    }
    
    private func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }
    
    private func scheduleRetry() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            print("Retrying to start hotkey monitoring...")
            self?.startMonitoring()
        }
    }
    
    private func handleEvent(_ event: CGEvent, type: CGEventType) -> Bool {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        
        if type == .flagsChanged {
            // Track CMD key state changes
            if keyCode == kLeftCmdKeyCode {
                leftCmdPressed = event.flags.contains(.maskCommand)
                print("Left CMD: \(leftCmdPressed ? "pressed" : "released")")
            } else if keyCode == kRightCmdKeyCode {
                rightCmdPressed = event.flags.contains(.maskCommand)
                print("Right CMD: \(rightCmdPressed ? "pressed" : "released")")
            }
            return false // Don't block flag changes
        }
        
        if type == .keyDown {
            // Check if right CMD is pressed and handle letter keys
            if rightCmdPressed && !leftCmdPressed {
                guard let character = keyCodeToCharacter(keyCode) else { return false }
                
                print("🎯 Right CMD + \(character) detected!")
                
                if let appPath = shortcuts[character] {
                    print("✅ Launching: \(appPath)")
                    AppLauncher.launchApplication(at: appPath)
                } else {
                    print("🔍 No shortcut configured for '\(character)'")
                }
                
                return true // Hijack the key combination
            }
            
            // Debug: Show all CMD combinations for troubleshooting
            if leftCmdPressed || rightCmdPressed {
                let character = keyCodeToCharacter(keyCode) ?? "unknown"
                let cmdSide = leftCmdPressed ? "Left" : "Right"
                print("🐛 \(cmdSide) CMD + \(character) (not hijacked)")
            }
        }
        
        return false // Don't block other events
    }
    
    private func keyCodeToCharacter(_ keyCode: Int) -> String? {
        let keyMap: [Int: String] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
            11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l", 38: "j",
            39: "'", 40: "k", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "n", 46: "m", 47: "."
        ]
        return keyMap[keyCode]
    }
}
