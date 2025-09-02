import Foundation
import AppKit

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String?
    let htmlUrl: String
    let publishedAt: String
    let prerelease: Bool
    let draft: Bool
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case prerelease
        case draft
    }
}

class UpdateChecker: ObservableObject {
    private let githubRepoOwner = "naveedehmad"
    private let githubRepoName = "KeyBoy"
    private let releasesAPIURL = "https://api.github.com/repos/naveedehmad/KeyBoy/releases/latest"
    
    @Published var isCheckingForUpdates = false
    @Published var updateAvailable = false
    @Published var latestRelease: GitHubRelease?
    @Published var error: String?
    
    private var currentVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        
        isCheckingForUpdates = true
        error = nil
        
        guard let url = URL(string: releasesAPIURL) else {
            self.error = "Invalid API URL"
            self.isCheckingForUpdates = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("KeyBoy/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10.0
        
        print("🔍 Checking for updates... Current version: \(currentVersion)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isCheckingForUpdates = false
                
                if let error = error {
                    self?.error = "Network error: \(error.localizedDescription)"
                    print("❌ Update check failed: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.error = "Invalid response"
                    print("❌ Invalid HTTP response")
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    self?.error = "Server returned status code: \(httpResponse.statusCode)"
                    print("❌ HTTP error: \(httpResponse.statusCode)")
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    print("❌ No data received from GitHub API")
                    return
                }
                
                do {
                    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                    print("✅ Retrieved latest release: \(release.tagName)")
                    
                    self?.latestRelease = release
                    self?.updateAvailable = self?.isNewerVersion(release.tagName, than: self?.currentVersion ?? "") ?? false
                    
                    if self?.updateAvailable == true {
                        print("🎉 Update available! Latest: \(release.tagName), Current: \(self?.currentVersion ?? "")")
                    } else {
                        print("✅ You have the latest version")
                    }
                    
                } catch {
                    self?.error = "Failed to parse response: \(error.localizedDescription)"
                    print("❌ JSON decode error: \(error)")
                }
            }
        }.resume()
    }
    
    private func isNewerVersion(_ remote: String, than local: String) -> Bool {
        let remoteVersion = remote.replacingOccurrences(of: "v", with: "")
        let localVersion = local.replacingOccurrences(of: "v", with: "")
        
        let remoteComponents = remoteVersion.components(separatedBy: ".").compactMap { Int($0) }
        let localComponents = localVersion.components(separatedBy: ".").compactMap { Int($0) }
        
        // Pad arrays to same length
        let maxLength = max(remoteComponents.count, localComponents.count)
        let paddedRemote = remoteComponents + Array(repeating: 0, count: maxLength - remoteComponents.count)
        let paddedLocal = localComponents + Array(repeating: 0, count: maxLength - localComponents.count)
        
        for (remote, local) in zip(paddedRemote, paddedLocal) {
            if remote > local {
                return true
            } else if remote < local {
                return false
            }
        }
        
        return false // Versions are equal
    }
    
    func showUpdateDialog() {
        guard let release = latestRelease else { return }
        
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = """
        KeyBoy \(release.tagName) is now available.
        You are currently using version \(currentVersion).
        
        \(release.body ?? "See release notes on GitHub for details.")
        """
        
        alert.addButton(withTitle: "Download Update")
        alert.addButton(withTitle: "Skip This Version")
        alert.addButton(withTitle: "Remind Me Later")
        
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn: // Download Update
            openGitHubRelease()
        case .alertSecondButtonReturn: // Skip This Version
            saveSkippedVersion(release.tagName)
        case .alertThirdButtonReturn: // Remind Me Later
            break // Do nothing, will check again next time
        default:
            break
        }
    }
    
    private func openGitHubRelease() {
        guard let release = latestRelease,
              let url = URL(string: release.htmlUrl) else { return }
        
        NSWorkspace.shared.open(url)
        print("🌐 Opened GitHub release page: \(release.htmlUrl)")
    }
    
    private func saveSkippedVersion(_ version: String) {
        UserDefaults.standard.set(version, forKey: "SkippedVersion")
        print("⏭️ Skipped version: \(version)")
    }
    
    private func isVersionSkipped(_ version: String) -> Bool {
        let skippedVersion = UserDefaults.standard.string(forKey: "SkippedVersion")
        return skippedVersion == version
    }
    
    func checkForUpdatesIfNeeded() {
        // Check if user has disabled auto-check
        if !UserDefaults.standard.bool(forKey: "AutoCheckForUpdates") {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: "AutoCheckForUpdates") == nil {
                UserDefaults.standard.set(true, forKey: "AutoCheckForUpdates")
            } else {
                return // User has disabled auto-check
            }
        }
        
        // Check for updates and show dialog if available
        checkForUpdates()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self,
                  let release = self.latestRelease,
                  self.updateAvailable,
                  !self.isVersionSkipped(release.tagName) else { return }
            
            self.showUpdateDialog()
        }
    }
}