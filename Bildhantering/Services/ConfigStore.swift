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

    var nikonCardPrefix: String = "Nikon" {
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
        nikonCardPrefix = UserDefaults.standard.string(forKey: "nikonCardPrefix") ?? "Nikon"
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

    // MARK: - Security-scoped bookmarks

    nonisolated func resolveURL(role: VolumeRole) -> URL? {
        guard let data = UserDefaults.standard.data(forKey: role.rawValue) else { return nil }
        var isStale = false
        return try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }

    /// Returns the URL with security scope already started.
    /// Caller **must** call `url.stopAccessingSecurityScopedResource()` when done.
    nonisolated func accessURL(role: VolumeRole) -> URL? {
        guard let url = resolveURL(role: role) else { return nil }
        _ = url.startAccessingSecurityScopedResource()
        return url
    }

    nonisolated func saveBookmark(url: URL, role: VolumeRole) throws {
        let data = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(data, forKey: role.rawValue)
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
        try? saveBookmark(url: url, role: role)
        switch role {
        case .cache: cacheBookmarkVersion += 1
        case .nas: nasBookmarkVersion += 1
        case .bildVerkstan: bildVerkstanBookmarkVersion += 1
        }
    }
}
