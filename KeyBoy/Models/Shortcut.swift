import Foundation

struct KeyBoyConfiguration: Codable {
    let shortcuts: [String: String]
    let settings: Settings?
    
    struct Settings: Codable {
        let showNotifications: Bool
        let playSound: Bool
        
        init() {
            self.showNotifications = false
            self.playSound = false
        }
    }
    
    init(shortcuts: [String: String] = [:], settings: Settings? = nil) {
        self.shortcuts = shortcuts
        self.settings = settings ?? Settings()
    }
    
    static func defaultConfiguration() -> KeyBoyConfiguration {
        return KeyBoyConfiguration(
            shortcuts: [
                "g": "/Applications/Ghostty.app",
                "a": "/Applications/Arc.app",
                "s": "/Applications/Slack.app",
                "c": "/Applications/Claude.app",
                "z": "/Applications/zoom.us.app"
            ]
        )
    }
}
