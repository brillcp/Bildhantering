import Foundation
import AppKit

enum VolumeRole: String {
    case cache = "cacheVolumeBookmark"
    case nas = "nasVolumeBookmark"
    case bildVerkstan = "bildVerkstanBookmark"
}

@Observable
final class ConfigStore {

    // MARK: - Stored properties (@Observable tracks these directly)

    var nikonCardPrefix: String = "NIKON" {
        didSet { UserDefaults.standard.set(nikonCardPrefix, forKey: "nikonCardPrefix") }
    }
    var signature: String = "ErS" {
        didSet { UserDefaults.standard.set(signature, forKey: "signature") }
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

    var cachePath: String? {
        didSet { UserDefaults.standard.set(cachePath, forKey: VolumeRole.cache.rawValue) }
    }
    var nasPath: String? {
        didSet { UserDefaults.standard.set(nasPath, forKey: VolumeRole.nas.rawValue) }
    }
    var bildVerkstanPath: String? {
        didSet { UserDefaults.standard.set(bildVerkstanPath, forKey: VolumeRole.bildVerkstan.rawValue) }
    }

    init() {
        nikonCardPrefix = UserDefaults.standard.string(forKey: "nikonCardPrefix") ?? "NIKON"
        signature       = UserDefaults.standard.string(forKey: "signature") ?? "ErS"
        lastFotodatum   = UserDefaults.standard.string(forKey: "lastFotodatum") ?? ""
        lastProjNamn    = UserDefaults.standard.string(forKey: "lastProjNamn") ?? ""
        lastArbNamn     = UserDefaults.standard.string(forKey: "lastArbNamn") ?? ""
        cachePath        = UserDefaults.standard.string(forKey: VolumeRole.cache.rawValue)
        nasPath          = UserDefaults.standard.string(forKey: VolumeRole.nas.rawValue)
        bildVerkstanPath = UserDefaults.standard.string(forKey: VolumeRole.bildVerkstan.rawValue)
    }

    // MARK: - Derived

    var cacheName: String?        { cachePath.map { URL(fileURLWithPath: $0).lastPathComponent } }
    var nasName: String?          { nasPath.map { URL(fileURLWithPath: $0).lastPathComponent } }
    var bildVerkstanName: String? { bildVerkstanPath.map { URL(fileURLWithPath: $0).lastPathComponent } }

    var isConfigured: Bool { cachePath != nil && nasPath != nil && bildVerkstanPath != nil }

    func resolveURL(role: VolumeRole) -> URL? {
        switch role {
        case .cache:        return cachePath.map { URL(fileURLWithPath: $0) }
        case .nas:          return nasPath.map { URL(fileURLWithPath: $0) }
        case .bildVerkstan: return bildVerkstanPath.map { URL(fileURLWithPath: $0) }
        }
    }

    func reset() {
        cachePath = nil
        nasPath = nil
        bildVerkstanPath = nil
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
            .cache: "Select Backup folder",
            .nas: "Select NAS folder",
            .bildVerkstan: "Select Bildverkstan folder"
        ]
        guard let url = await pickFolder(prompt: prompts[role] ?? "Select folder") else { return }
        switch role {
        case .cache:        cachePath = url.path
        case .nas:          nasPath = url.path
        case .bildVerkstan: bildVerkstanPath = url.path
        }
    }
}
