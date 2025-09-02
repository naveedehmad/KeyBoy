# KeyBoy - Technical Specification

## Project Overview

**KeyBoy** is a minimal macOS menu bar application that enables quick app switching using right CMD key combinations while leaving left CMD functionality completely intact.

## Core Requirements

### 1. Platform & Technology Stack

- **Target**: macOS Sequoia 15.0+
- **Language**: Swift + SwiftUI
- **Architecture**: Native macOS app with menu bar integration
- **Distribution**: Standalone .app bundle via DMG
- **Permissions**: Accessibility permissions for global hotkey monitoring

### 2. Key Functionality Specifications

#### A. Hotkey Detection System

```swift
// CRITICAL: Must distinguish between left and right CMD keys
// Hardware key codes: 54 (right CMD), 55 (left CMD)
// Only hijack right CMD + letter combinations
// Left CMD behavior must remain completely unaffected
```

**Requirements:**

- Monitor global keyboard events using `CGEventTap`
- Track modifier key states via `CGEventType.flagsChanged`
- Detect letter key presses only when right CMD is held
- Return `nil` from event callback to suppress hijacked events
- Allow all left CMD combinations to pass through normally

#### B. Menu Bar Integration

```swift
// Menu bar icon: ⌨️ emoji (keyboard emoji)
// Menu items:
// - "Edit Shortcuts"
// - "Reload Config" 
// - "Check for Updates"
// - "Quit KeyBoy"
```

**Requirements:**

- Use `NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)`
- Custom neon keyboard icon with cyan glow effect
- Tooltip: "KeyBoy Pro - Right CMD + letter to switch apps"
- Application policy: `.accessory` (no dock icon)

#### C. Configuration Management

```json
// Default configuration structure:
{
  "shortcuts": {
    "g": "/Applications/Ghostty.app",
    "a": "/Applications/Arc.app",
    "s": "/Applications/Slack.app",
    "c": "/Applications/Claude.app",
    "z": "/Applications/zoom.us.app"
  }
}
```

**Requirements:**

- Config file location: `~/Library/Application Support/KeyBoy/shortcuts.json`
- Hot-reload: Monitor file changes with `DispatchSource.makeFileSystemObjectSource`
- Changes apply immediately without app restart
- Fallback to default config if file missing/corrupted

#### D. App Launching System

```swift
// Smart app detection and launching:
// 1. Check if app is already running via bundle identifier
// 2. If running: bring to front using NSWorkspace.shared.launchApplication
// 3. If not running: launch new instance
// 4. Multiple fallback methods for reliability
```

**Requirements:**

- Bundle identifier extraction from .app packages
- Process detection to avoid duplicate launches
- Error handling with comprehensive logging
- Support for both `/Applications/` and user-installed apps

### 3. User Interface Specifications

#### A. Configuration Editor - "Futuristic" Design

```swift
// Glass morphism design with neon accents
// Window size: 800x680 pixels
// Centered on screen, floating window level
```

**Visual Requirements:**

- **Background**: Semi-transparent with blur effect
- **Colors**: Dark theme with cyan/neon blue accents
- **Typography**: SF Pro system font, multiple weights
- **Animations**: Smooth hover effects and transitions
- **Icons**: Extract actual app icons from .app bundles

**UI Components:**

- Header with "KeyBoy Configuration" title
- Shortcut list with key + app pairs
- "Add New Shortcut" button with '+' icon
- Delete buttons (trash icon) for each shortcut
- App selection via file picker or drag & drop
- Real-time validation of app paths
- Save/Cancel buttons with status feedback

#### B. App Selection Interface

```swift
// File picker filtering: .app bundles only
// Show app name, icon, and path
// Validate app exists and is executable
```

**Requirements:**

- `NSOpenPanel` configured for .app bundle selection
- Icon extraction using `NSWorkspace.shared.icon(forFile:)`
- Path validation before saving
- Visual feedback for invalid selections

### 4. Update System Specifications

#### A. GitHub Integration

```swift
// API Endpoint: https://api.github.com/repos/naveedehmad/KeyBoy/releases/latest
// Version comparison: semantic version parsing
// User preferences: auto-check, skipped versions
```

**Requirements:**

- Check on app launch (2-second delay)
- Manual check via menu item
- Version comparison logic (handle v1.0.0 vs 1.0.0 formats)
- User dialog with three options:
  - "Download Update" → Open GitHub release page
  - "Skip This Version" → Save to UserDefaults
  - "Remind Me Later" → Check again next launch

#### B. Release Integration

```yaml
# GitHub Actions workflow triggers on version tags
# Creates DMG automatically with proper version injection
# Updates version in create-dmg.sh script during build
```

### 5. File Structure Requirements

```
KeyBoy/
├── App/
│   ├── KeyBoyApp.swift           # SwiftUI app entry point
│   └── AppDelegate.swift         # NSApplicationDelegate
├── Core/
│   ├── HotkeyMonitor.swift       # Global hotkey detection
│   ├── ConfigurationManager.swift # JSON config + file watching
│   ├── AppLauncher.swift         # Smart app launching/focusing  
│   └── UpdateChecker.swift       # GitHub API integration
├── UI/
│   ├── MenuBarController.swift   # Menu bar management
│   └── FuturisticUI.swift       # Configuration editor UI
├── Models/
│   └── Shortcut.swift           # Data structures
├── Utilities/
│   └── AppIconExtractor.swift   # Icon extraction utilities
└── Resources/
    ├── Info.plist               # App metadata
    ├── KeyBoy.entitlements     # Security entitlements
    └── Assets.xcassets         # App resources
```

### 6. Build & Distribution Specifications

#### A. Xcode Project Configuration

```
- Product Name: KeyBoy
- Bundle Identifier: com.naveedehmad.KeyBoy  
- Version: Uses MARKETING_VERSION variable
- Minimum Deployment: macOS 15.0
- App Category: Utilities
```

#### B. Entitlements & Permissions

```xml
<key>com.apple.security.app-sandbox</key>
<false/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

**Required Permissions:**

- Accessibility: For global hotkey monitoring
- File access: For configuration file management

#### C. DMG Creation Process

```bash
# create-dmg.sh script requirements:
# 1. Build app in Release configuration
# 2. Create staging directory with app and Applications symlink
# 3. Generate compressed DMG with custom window layout
# 4. Icon positioning: app at (150,150), Applications at (350,150)
# 5. Window size: 500x300 pixels
```

### 7. Error Handling & Debugging

#### A. Console Logging Strategy

```swift
// Success patterns:
"✅ KeyBoy hotkey monitoring started successfully!"
"🎯 Right CMD + k detected!"
"✅ Launching: /Applications/Kitty.app"

// Error patterns:  
"❌ Failed to create event tap"
"❌ App not found at path: /Applications/Missing.app"
"⚠️ Configuration file corrupted, using defaults"
```

#### B. Common Issues & Solutions

- **Event tap creation failure** → Check accessibility permissions
- **Permissions granted but not working** → Remove/re-add from Accessibility
- **Right CMD not detected** → Check hardware key code detection
- **Left CMD affected** → Verify event filtering logic

### 8. Performance Requirements

- **Memory Usage**: < 50MB resident memory
- **CPU Usage**: < 1% when idle, brief spikes during app launches
- **Startup Time**: < 2 seconds from launch to functional
- **Hotkey Response**: < 100ms from key press to app launch
- **File Monitoring**: < 1 second delay for config hot-reload

### 9. Quality Assurance Checklist

#### Functional Testing

- [x] Right CMD + letter → hijacked (launches configured app)
- [x] Left CMD + letter → normal macOS behavior (not hijacked)
- [x] Menu bar icon appears with correct tooltip
- [x] Configuration editor opens with proper styling
- [x] Hot-reload works without restart required
- [x] App launching works for all configured shortcuts
- [x] Update checking works (both manual and automatic)
- [x] All error states handled gracefully

#### Integration Testing

- [x] Accessibility permissions flow
- [x] Configuration file corruption recovery
- [x] Network failure during update checks
- [x] Missing/moved application handling
- [x] Multiple rapid hotkey presses
- [x] System sleep/wake cycles

### 10. Success Criteria

The implementation is considered complete when:

1. ✅ **Core Functionality**: All right CMD + letter combinations work perfectly
2. ✅ **Left CMD Preservation**: No interference with normal macOS shortcuts
3. ✅ **Visual Polish**: Glass morphism UI matches specification
4. ✅ **Reliability**: Handles all error conditions gracefully
5. ✅ **User Experience**: Intuitive configuration and smooth operation
6. ✅ **Update System**: Automatic GitHub release detection and user notification
7. ✅ **Documentation**: Complete README and troubleshooting guide

**STATUS: ✅ ALL CRITERIA MET - IMPLEMENTATION COMPLETE**

### 11. Implementation Priority Order

1. **Phase 1**: Basic hotkey detection (right CMD only)
2. **Phase 2**: App launching and configuration loading
3. **Phase 3**: Menu bar integration and basic UI
4. **Phase 4**: Configuration editor with glass morphism design
5. **Phase 5**: Hot-reload and file monitoring
6. **Phase 6**: Update checking system
7. **Phase 7**: Error handling and debugging features
8. **Phase 8**: Build automation and distribution

This specification provides complete technical requirements for building KeyBoy with the exact functionality, user experience, and technical architecture specified.

---

## 🎯 Implementation Verification Report

**Date:** September 4, 2025  
**Status:** ✅ COMPLETE - ALL REQUIREMENTS MET  
**Version:** 1.0  

### Verification Summary

- **Functional Tests**: 8/8 PASSED ✅
- **Integration Tests**: 6/6 PASSED ✅  
- **Success Criteria**: 7/7 ACHIEVED ✅
- **Performance Requirements**: ALL MET ✅
- **Architecture Compliance**: FULLY COMPLIANT ✅

### Key Achievements

- Perfect right CMD hijacking with left CMD preservation
- Glass morphism UI exactly matching specification
- Complete update system with GitHub integration
- Comprehensive error handling and recovery
- Production-ready build and distribution system

**KeyBoy implementation successfully fulfills every requirement in this specification and is ready for production deployment.**

