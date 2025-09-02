# CLAUDE.md - AI Assistant Context for KeyBoy

## Project Overview
**KeyBoy** is a minimal macOS menu bar application that enables quick app switching using right CMD key combinations. The app hijacks only right CMD key presses while leaving left CMD behavior completely intact.

**Core Functionality**: Right CMD + letter → Launch/focus specific applications

## Quick Understanding

### What This App Does
- Shows ⌨️ emoji in macOS menu bar
- Intercepts right CMD + letter combinations (a-z)
- Launches or focuses configured applications
- Provides JSON configuration editor via menu bar
- Ignores left CMD completely (normal macOS behavior continues)

### What Makes This Special
- **Right CMD Only**: Precisely hijacks right CMD, leaves left CMD alone
- **System Integration**: Native menu bar app with proper macOS behavior
- **Hot Reload**: Config changes apply immediately without restart
- **Minimal Design**: No over-engineering, focused on core functionality

## Architecture Summary

```
KeyBoy/
├── App/                    # SwiftUI app entry + NSApplicationDelegate
├── Core/                   # Business logic
│   ├── HotkeyMonitor      # Global key detection (the complex part)
│   ├── ConfigurationManager # JSON config with file watching
│   └── AppLauncher        # Smart app launching/focusing
├── UI/                     # Menu bar + config editor
├── Models/                 # Data structures
└── Resources/             # Info.plist, entitlements
```

## Key Technical Components

### 1. HotkeyMonitor.swift - The Heart of the App
**Challenge Solved**: Distinguishing left vs right CMD keys reliably
**Solution**: 
- Monitor `CGEventType.flagsChanged` for modifier key states
- Use hardware key codes: 54 (right CMD), 55 (left CMD)
- Track state: only hijack when `rightCmdPressed && !leftCmdPressed`
- Return `nil` from callback to suppress hijacked events

### 2. ConfigurationManager.swift - Live Configuration
- JSON config at `~/Library/Application Support/KeyBoy/shortcuts.json`
- `DispatchSource.makeFileSystemObjectSource` for file monitoring
- Hot-reload: changes apply immediately
- Default config includes Kitty, Arc, Slack, Claude, Zoom apps

### 3. AppLauncher.swift - Smart App Switching
- Detects if app is running via bundle identifier
- Focuses existing apps or launches new instances
- Multiple fallback methods for reliability
- Comprehensive error logging

## Current Default Configuration
```json
{
  "shortcuts": {
    "k": "/Applications/Kitty.app",
    "a": "/Applications/Arc.app",
    "s": "/Applications/Slack.app",
    "c": "/Applications/Claude.app",
    "z": "/Applications/zoom.us.app"
  }
}
```

## Critical Technical Details

### Accessibility Permissions Quirk
**Major Issue**: macOS caches permission state
**Solution**: Must **remove and re-add** KeyBoy from Accessibility permissions
**Why**: Simple permission toggle doesn't refresh macOS permission cache
**Impact**: This solves 90% of "app not working" issues

### Right CMD Detection Evolution
1. **Failed**: `CGEventFlags.maskSecondaryFn` approach
2. **Failed**: Flag combination detection
3. **Success**: Hardware key code detection with state tracking

### Event Handling Logic
```swift
// Monitor both keyDown and flagsChanged events
// Track CMD key states separately
// Only hijack when rightCmdPressed && !leftCmdPressed
// Return nil to suppress, original event to allow through
```

## Build & Development Notes

### Requirements
- macOS Sequoia 15.0+
- Xcode 15.0+
- Accessibility permissions (with remove/re-add quirk)

### Testing Checklist
- Right CMD + letter → hijacked (app launches)
- Left CMD + letter → normal behavior (not hijacked)
- Menu bar icon appears
- Config editor works
- Hot-reload functional

### Common Issues & Solutions
1. **"Failed to create event tap"** → Check accessibility permissions
2. **"Permissions granted but not working"** → Remove/re-add from Accessibility
3. **"Right CMD not detected"** → Check Console for debug messages
4. **"Apps not launching"** → Verify paths in config file

## User Experience Flow

### First Time Setup
1. Launch app → ⌨️ appears in menu bar
2. System prompts for accessibility permissions
3. If shortcuts don't work → remove/re-add permission
4. Use Right CMD + K/A/S/C/Z for default apps

### Daily Usage
- Right CMD + letter → instant app switching
- Click ⌨️ → access config editor
- Edit JSON → changes apply immediately
- Left CMD works normally for system shortcuts

### Configuration
- Click menu bar → "Edit Shortcuts"
- JSON editor with syntax validation
- Save → immediate activation
- Add any single letter → app path mapping

## Debug Information

### Console Output (when working)
```
✅ KeyBoy hotkey monitoring started successfully!
Right CMD: pressed
🎯 Right CMD + k detected!
✅ Launching: /Applications/Kitty.app
```

### Error Patterns
- "Failed to create event tap" → permissions issue
- "Right CMD: false" → key detection issue  
- "App not found" → path issue in config

## Extension Points

### Easy Enhancements
- Add more default shortcuts
- Support additional modifier combinations
- Visual config editor (beyond JSON)
- App icon display in menu

### Complex Enhancements
- Multiple key combinations (CMD+Shift+letter)
- Global hotkey sequences
- App-specific context awareness
- Launch at login integration

## Development Philosophy Applied

### What Worked
- **Minimal scope**: Focused only on core functionality
- **Comprehensive debugging**: Made issues visible and solvable
- **Iterative problem-solving**: Multiple approaches until success
- **User feedback integration**: Real-world testing drove solutions

### Avoided Pitfalls
- **Over-engineering**: Resisted adding unnecessary features
- **Assumption-based development**: Actually tested on real macOS behavior
- **Poor error handling**: Added extensive logging and recovery

## For Future AI Assistants

### Understanding This Codebase
1. **Read HANDOFF_SESSION.md** for complete development journey
2. **Check README.md** for build instructions and troubleshooting
3. **Review Console output** for runtime behavior
4. **Test left vs right CMD** behavior specifically

### Common Requests & Solutions
- **"Shortcuts not working"** → Accessibility permissions remove/re-add
- **"Add new shortcut"** → Edit shortcuts.json or use config editor
- **"Left CMD affected"** → Check HotkeyMonitor logic, should only hijack right CMD
- **"App won't launch"** → Verify app path, check AppLauncher debug output

### Key Files to Modify
- **Add shortcuts**: KeyBoy/Models/Shortcut.swift (defaultConfiguration)
- **Fix key detection**: KeyBoy/Core/HotkeyMonitor.swift
- **App launching issues**: KeyBoy/Core/AppLauncher.swift
- **UI changes**: KeyBoy/UI/* files

## Success Metrics
- ✅ Right CMD hijacking works perfectly
- ✅ Left CMD unaffected (normal macOS behavior)  
- ✅ All default apps launch correctly
- ✅ Config hot-reload functional
- ✅ Accessibility permissions documented and working
- ✅ Comprehensive debugging available

This app is **production-ready** for personal use and **well-documented** for maintenance or enhancement.