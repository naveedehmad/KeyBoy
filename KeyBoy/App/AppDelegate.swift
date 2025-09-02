import SwiftUI
import AppKit
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var hotkeyMonitor: HotkeyMonitor?
    private var configurationManager: ConfigurationManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Show permission dialog if needed, but don't block startup
        requestAccessibilityPermissionsIfNeeded()
        
        setupApplication()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyMonitor?.stopMonitoring()
    }
    
    private func requestAccessibilityPermissionsIfNeeded() {
        let trusted = AXIsProcessTrusted()
        
        if !trusted {
            print("🔐 KeyBoy needs Accessibility permissions to monitor keyboard shortcuts.")
            print("   The system dialog will appear to grant permissions.")
            
            // Show system permission dialog
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        } else {
            print("✅ Accessibility permissions already granted")
        }
    }
    
    private func setupApplication() {
        configurationManager = ConfigurationManager()
        menuBarController = MenuBarController(configurationManager: configurationManager!)
        hotkeyMonitor = HotkeyMonitor(configurationManager: configurationManager!)
        
        configurationManager?.loadConfiguration()
        menuBarController?.setupMenuBar()
        hotkeyMonitor?.startMonitoring()
        
        // Check for updates on launch
        menuBarController?.checkForUpdatesOnLaunch()
    }
}