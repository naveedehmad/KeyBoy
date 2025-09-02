import Foundation
import AppKit

class AppLauncher {
    static func launchApplication(at path: String) {
        print("🚀 Attempting to launch app at: \(path)")
        
        let url = URL(fileURLWithPath: path)
        
        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ Application not found at path: \(path)")
            return
        }
        
        print("✅ App exists at path")
        
        // Try to get bundle info
        if let bundle = Bundle(url: url) {
            let bundleIdentifier = bundle.bundleIdentifier ?? "unknown"
            let appName = bundle.infoDictionary?["CFBundleDisplayName"] as? String ?? 
                         bundle.infoDictionary?["CFBundleName"] as? String ?? 
                         url.lastPathComponent
            
            print("📦 Bundle ID: \(bundleIdentifier)")
            print("📱 App Name: \(appName)")
            
            // Check if app is already running
            let runningApps = NSWorkspace.shared.runningApplications
            if let runningApp = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
                print("🔄 App already running, bringing to front...")
                let success = runningApp.activate(options: .activateIgnoringOtherApps)
                print(success ? "✅ Successfully activated app" : "❌ Failed to activate app")
                return
            }
        }
        
        print("🆕 App not running, launching new instance...")
        launchNewApplication(at: url)
    }
    
    private static func launchNewApplication(at url: URL) {
        print("🔧 Trying NSWorkspace.shared.launchApplication...")
        
        do {
            try NSWorkspace.shared.launchApplication(at: url, options: [], configuration: [:])
            print("✅ Successfully launched with NSWorkspace: \(url.lastPathComponent)")
        } catch {
            print("❌ NSWorkspace launch failed: \(error)")
            print("🔧 Trying fallback with 'open' command...")
            
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [url.path]
            
            do {
                try task.run()
                print("✅ Successfully launched with 'open': \(url.lastPathComponent)")
            } catch {
                print("❌ 'open' command also failed: \(error)")
                print("💡 You may need to launch the app manually or check the app path")
            }
        }
    }
}