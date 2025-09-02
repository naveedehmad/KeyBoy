import AppKit
import SwiftUI

class MenuBarController {
    private var statusItem: NSStatusItem?
    private var configurationManager: ConfigurationManager
    private var configWindow: NSWindow?
    private var windowDelegate: ConfigWindowDelegate?
    private var updateChecker: UpdateChecker
    
    init(configurationManager: ConfigurationManager) {
        self.configurationManager = configurationManager
        self.updateChecker = UpdateChecker()
    }
    
    func setupMenuBar() {
        print("🚀 Starting menu bar setup...")
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            print("❌ Failed to create status item")
            return
        }
        
        print("✅ Status item created successfully")
        
        if let button = statusItem.button {
            // Create a custom keyboard icon with neon effect
            let keyboardIcon = createNeonKeyboardIcon()
            button.image = keyboardIcon
            
            button.toolTip = "KeyBoy Pro - Right CMD + letter to switch apps"
        } else {
            print("❌ Failed to get status item button")
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Edit Shortcuts", action: #selector(editShortcuts), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Check for Updates", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit KeyBoy", action: #selector(quitApp), keyEquivalent: "q"))
        
        for item in menu.items {
            item.target = self
        }
        
        statusItem.menu = menu
        print("✅ Menu bar setup completed - ⌨️ should now be visible in menu bar")
    }
    
    @objc private func editShortcuts() {
        showConfigEditor()
    }
    
    @objc private func reloadConfig() {
        configurationManager.loadConfiguration()
        print("Configuration reloaded manually")
    }
    
    @objc private func checkForUpdates() {
        print("🔍 Checking for updates manually...")
        updateChecker.checkForUpdates()
        
        // Show appropriate feedback after check completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            if let error = self.updateChecker.error {
                self.showUpdateError(error)
            } else if self.updateChecker.updateAvailable {
                self.updateChecker.showUpdateDialog()
            } else {
                self.showUpToDateDialog()
            }
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func checkForUpdatesOnLaunch() {
        // Check for updates automatically on app launch (with user preferences)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.updateChecker.checkForUpdatesIfNeeded()
        }
    }
    
    private func showUpdateError(_ error: String) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Could not check for updates: \(error)"
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        alert.runModal()
    }
    
    private func showUpToDateDialog() {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        
        let alert = NSAlert()
        alert.messageText = "KeyBoy is Up to Date"
        alert.informativeText = "You are running the latest version (\(currentVersion))."
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    private func showConfigEditor() {
        if configWindow == nil {
            let futuristicConfigView = FuturisticConfigEditorView(configurationManager: configurationManager) { [weak self] in
                self?.configWindow?.close()
                self?.configWindow = nil
            }
            
            let hostingController = NSHostingController(rootView: futuristicConfigView)
            
            print("🔍 Creating window...")
            configWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 680),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            print("🔍 Initial window frame: \(configWindow?.frame ?? .zero)")
            print("🔍 Screen info: \(NSScreen.main?.frame ?? .zero)")
            print("🔍 Screen visible frame: \(NSScreen.main?.visibleFrame ?? .zero)")
            
            configWindow?.title = "KeyBoy - Configuration"
            configWindow?.contentViewController = hostingController
            
            // CRITICAL: The hosting controller corrupts the window size, so we need to restore it
            configWindow?.setFrame(NSRect(x: 0, y: 0, width: 800, height: 680), display: false)
            print("🔍 After restoring size - window frame: \(configWindow?.frame ?? .zero)")
            
            configWindow?.backgroundColor = NSColor.windowBackgroundColor
            configWindow?.isReleasedWhenClosed = false
            
            // Now center the properly sized window
            configWindow?.center()
            print("🔍 After center - window frame: \(configWindow?.frame ?? .zero)")
            
            // Force window to front and keep it there
            configWindow?.level = .floating
            configWindow?.makeKeyAndOrderFront(nil)
            print("🔍 Final window frame: \(configWindow?.frame ?? .zero)")
            
            configWindow?.orderFrontRegardless()
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            print("🔍 Final window frame: \(configWindow?.frame ?? .zero)")
            
            windowDelegate = ConfigWindowDelegate { [weak self] in
                self?.configWindow = nil
                self?.windowDelegate = nil
            }
            configWindow?.delegate = windowDelegate
        } else {
            // If window already exists, bring it to front
            configWindow?.level = .floating
            configWindow?.makeKeyAndOrderFront(nil)
            configWindow?.orderFrontRegardless()
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    private func createNeonKeyboardIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create a glow effect context
        let context = NSGraphicsContext.current?.cgContext
        context?.setShadow(offset: CGSize(width: 0, height: 0), blur: 3, color: NSColor.cyan.cgColor)
        
        // Draw the keyboard symbol
        let symbolImage = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 14, weight: .semibold))
        
        if let symbolImage = symbolImage {
            // Draw with cyan tint
            NSColor.cyan.set()
            let rect = NSRect(origin: .zero, size: size)
            symbolImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }
        
        image.unlockFocus()
        image.isTemplate = false
        
        return image
    }
}

private class ConfigWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
