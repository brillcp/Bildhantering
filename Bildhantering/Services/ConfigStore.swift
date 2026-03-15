import Foundation
import AppKit

enum VolumeRole: String {
    case cache = "cacheVolumeBookmark"
    case nas = "nasVolumeBookmark"
    case bildVerkstan = "bildVerkstanBookmark"
}

@Observable
final class ConfigStore {

    // MARK: - Last-used metadata (stored properties for @Observable tracking)

    var nikonCardPrefix: String = "NIKON" {
        didSet { UserDefaults.standard.set(nikonCardPrefix, forKey: "nikonCardPrefix") }
    }
    var lastFotodatum: String = "" {
        didSet { UserDefaults.standard.set(lastFotodatum, forKey: "lastFotodatum") }
    }
    var lastProjNamn: String = "" {
        didSet { UserDefaults.standard.set(lastProjNamn, forKey: "lastProjNamn") }
    }
    var lastArbNamn: String = "" {
        didSet { UserDefaults.standard.set(lastArbNamn, forKey: "lastArbNamn") }
    }

    // Trigger UI updates when bookmarks change
    var cacheBookmarkVersion: Int = 0
    var nasBookmarkVersion: Int = 0
    var bildVerkstanBookmarkVersion: Int = 0

    init() {
        nikonCardPrefix = UserDefaults.standard.string(forKey: "nikonCardPrefix") ?? "NIKON"
        lastFotodatum = UserDefaults.standard.string(forKey: "lastFotodatum") ?? ""
        lastProjNamn = UserDefaults.standard.string(forKey: "lastProjNamn") ?? ""
        lastArbNamn = UserDefaults.standard.string(forKey: "lastArbNamn") ?? ""
    }

    // MARK: - Display names
    // Each property reads its version counter so @Observable registers the dependency.
    // When pickVolume() increments the counter, SwiftUI re-evaluates these computed properties.

    var cacheName: String? {
        _ = cacheBookmarkVersion
        return resolveURL(role: .cache)?.lastPathComponent
    }
    var nasName: String? {
        _ = nasBookmarkVersion
        return resolveURL(role: .nas)?.lastPathComponent
    }
    var bildVerkstanName: String? {
        _ = bildVerkstanBookmarkVersion
        return resolveURL(role: .bildVerkstan)?.lastPathComponent
    }

    var isConfigured: Bool {
        cacheName != nil && nasName != nil && bildVerkstanName != nil
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: VolumeRole.cache.rawValue)
        UserDefaults.standard.removeObject(forKey: VolumeRole.nas.rawValue)
        UserDefaults.standard.removeObject(forKey: VolumeRole.bildVerkstan.rawValue)
        cacheBookmarkVersion += 1
        nasBookmarkVersion += 1
        bildVerkstanBookmarkVersion += 1
    }

    // MARK: - URL storage (plain paths — sandbox disabled, no security scope needed)

    nonisolated func resolveURL(role: VolumeRole) -> URL? {
        guard let path = UserDefaults.standard.string(forKey: role.rawValue), !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path)
    }

    private func savePath(url: URL, role: VolumeRole) {
        UserDefaults.standard.set(url.path, forKey: role.rawValue)
    }

    // MARK: - Folder pickers

    func pickFolder(prompt: String) async -> URL? {
        let panel = NSOpenPanel()
        panel.message = prompt
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url
    }

    func pickVolume(role: VolumeRole) async {
        let prompts: [VolumeRole: String] = [
            .cache: "Select Cache / RAW_2 drive root folder",
            .nas: "Select NAS / RAW_1 drive root folder",
            .bildVerkstan: "Select BILD_verkstan folder"
        ]
        guard let url = await pickFolder(prompt: prompts[role] ?? "Select folder") else { return }
        savePath(url: url, role: role)
        switch role {
        case .cache: cacheBookmarkVersion += 1
        case .nas: nasBookmarkVersion += 1
        case .bildVerkstan: bildVerkstanBookmarkVersion += 1
        }
    }
}
