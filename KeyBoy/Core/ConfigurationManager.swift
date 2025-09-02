import Foundation
import Combine

class ConfigurationManager: ObservableObject {
    @Published var configuration: KeyBoyConfiguration = KeyBoyConfiguration()
    
    private var fileMonitor: DispatchSourceFileSystemObject?
    private let configDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("KeyBoy")
    private let configFile = "shortcuts.json"
    private var ignoringFileChanges = false
    
    var onConfigurationChanged: (([String: String]) -> Void)?
    
    private var configFileURL: URL {
        return configDirectory.appendingPathComponent(configFile)
    }
    
    func loadConfiguration() {
        createConfigDirectoryIfNeeded()
        
        if !FileManager.default.fileExists(atPath: configFileURL.path) {
            createDefaultConfiguration()
        }
        
        do {
            let data = try Data(contentsOf: configFileURL)
            let decoder = JSONDecoder()
            configuration = try decoder.decode(KeyBoyConfiguration.self, from: data)
            onConfigurationChanged?(configuration.shortcuts)
            print("Configuration loaded: \(configuration.shortcuts.count) shortcuts")
            startFileMonitoring()
        } catch {
            print("Failed to load configuration: \(error)")
            createDefaultConfiguration()
        }
    }
    
    func saveConfiguration(_ newConfiguration: KeyBoyConfiguration) {
        print("💾 ConfigManager: Saving to \(configFileURL.path)")
        print("💾 ConfigManager: Saving \(newConfiguration.shortcuts.count) shortcuts")
        
        // Temporarily ignore file changes to prevent reload loop
        ignoringFileChanges = true
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let data = try encoder.encode(newConfiguration)
            try data.write(to: configFileURL)
            
            configuration = newConfiguration
            onConfigurationChanged?(newConfiguration.shortcuts)
            print("✅ Configuration saved successfully to file")
            print("✅ onConfigurationChanged called with \(newConfiguration.shortcuts.count) shortcuts")
            
            // Re-enable file monitoring after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.ignoringFileChanges = false
            }
        } catch {
            print("❌ Failed to save configuration: \(error)")
            ignoringFileChanges = false
        }
    }
    
    func getConfigurationAsJSON() -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            let data = try encoder.encode(configuration)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            print("Failed to encode configuration as JSON: \(error)")
            return "{}"
        }
    }
    
    func updateConfigurationFromJSON(_ jsonString: String) throws {
        print("💾 ConfigManager: updateConfigurationFromJSON called")
        
        // Remove any byte order marks or invisible characters at the start
        var cleanedString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove BOM if present
        if cleanedString.hasPrefix("\u{FEFF}") {
            cleanedString.removeFirst()
        }
        
        guard let data = cleanedString.data(using: .utf8, allowLossyConversion: true) else {
            throw NSError(domain: "ConfigManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON string to data"])
        }
        
        do {
            // First, try to parse as generic JSON to clean it up
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                
                // Re-serialize to get clean JSON
                let cleanData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
                
                // Now decode properly
                let decoder = JSONDecoder()
                let newConfiguration = try decoder.decode(KeyBoyConfiguration.self, from: cleanData)
                
                print("💾 ConfigManager: JSON parsed successfully, calling saveConfiguration")
                saveConfiguration(newConfiguration)
            } else {
                throw NSError(domain: "ConfigManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
            }
        } catch {
            print("❌ JSON processing failed: \(error)")
            
            // Try to identify the problematic character
            let lines = cleanedString.components(separatedBy: .newlines)
            if lines.count >= 12 {
                print("Line 12: \(lines[11])")
                if lines[11].count >= 37 {
                    let index = lines[11].index(lines[11].startIndex, offsetBy: 36)
                    print("Character around column 37: '\(lines[11][index])'")
                }
            }
            
            throw error
        }
    }

    private func createConfigDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: configDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
                print("Created config directory: \(configDirectory.path)")
            } catch {
                print("Failed to create config directory: \(error)")
            }
        }
    }
    
    private func createDefaultConfiguration() {
        let defaultConfig = KeyBoyConfiguration.defaultConfiguration()
        saveConfiguration(defaultConfig)
        print("Created default configuration")
    }
    
    private func startFileMonitoring() {
        stopFileMonitoring()
        
        let descriptor = open(configFileURL.path, O_EVTONLY)
        guard descriptor != -1 else {
            print("Failed to open config file for monitoring")
            return
        }
        
        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )
        
        fileMonitor?.setEventHandler { [weak self] in
            guard let self = self, !self.ignoringFileChanges else {
                print("📁 File change detected but ignoring (save in progress)")
                return
            }
            print("📁 Config file changed, reloading...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.reloadConfiguration()
            }
        }
        
        fileMonitor?.setCancelHandler {
            close(descriptor)
        }
        
        fileMonitor?.resume()
        print("File monitoring started")
    }
    
    private func stopFileMonitoring() {
        fileMonitor?.cancel()
        fileMonitor = nil
    }
    
    private func reloadConfiguration() {
        do {
            let data = try Data(contentsOf: configFileURL)
            let decoder = JSONDecoder()
            let newConfiguration = try decoder.decode(KeyBoyConfiguration.self, from: data)
            
            DispatchQueue.main.async {
                self.configuration = newConfiguration
                self.onConfigurationChanged?(newConfiguration.shortcuts)
                print("🔄 Configuration reloaded from file - \(newConfiguration.shortcuts.count) shortcuts:")
                for (key, app) in newConfiguration.shortcuts.sorted(by: { $0.key < $1.key }) {
                    print("   \(key) → \(app)")
                }
            }
        } catch {
            print("❌ Failed to reload configuration: \(error)")
        }
    }
    
    deinit {
        stopFileMonitoring()
    }
}
