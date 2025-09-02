import AppKit
import Foundation

struct AppInfo {
    let name: String
    let icon: NSImage?
    let path: String
}

class AppIconExtractor {
    
    static func extractAppInfo(from appPath: String) -> AppInfo? {
        let url = URL(fileURLWithPath: appPath)
        
        // Ensure it's an app bundle
        guard url.pathExtension == "app" else {
            return nil
        }
        
        // Get app name from bundle
        let appName = url.deletingPathExtension().lastPathComponent
        
        // Try to get icon from app bundle
        let icon = extractIcon(from: url)
        
        return AppInfo(name: appName, icon: icon, path: appPath)
    }
    
    private static func extractIcon(from appURL: URL) -> NSImage? {
        // Try to get icon from bundle
        if let bundle = Bundle(url: appURL) {
            // Try to get icon from Info.plist
            if let iconFileName = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String {
                var iconPath = iconFileName
                
                // Add .icns extension if not present
                if !iconPath.hasSuffix(".icns") {
                    iconPath += ".icns"
                }
                
                let iconURL = appURL.appendingPathComponent("Contents/Resources/\(iconPath)")
                if let icon = NSImage(contentsOf: iconURL) {
                    return icon
                }
            }
            
            // Try common icon names
            let commonIconNames = ["app.icns", "icon.icns", "AppIcon.icns"]
            for iconName in commonIconNames {
                let iconURL = appURL.appendingPathComponent("Contents/Resources/\(iconName)")
                if let icon = NSImage(contentsOf: iconURL) {
                    return icon
                }
            }
        }
        
        // Fallback to system icon for app
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
    
    static func isValidApp(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        
        // Check if it's an .app bundle
        guard url.pathExtension == "app" else {
            return false
        }
        
        // Check if it exists and is a directory
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        
        return exists && isDirectory.boolValue
    }
}