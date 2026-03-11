import Foundation
import AppKit

@Observable
final class VolumeMonitor {

    var mountedVolumes: [String: URL] = [:]   // name → URL
    var nikonCard: URL?

    private var nikonPrefix: String = "Nikon"
    private var observers: [NSObjectProtocol] = []

    // Notification names via string to be SDK-version agnostic
    private static let didMount = Notification.Name("NSWorkspaceDidMountNotification")
    private static let didUnmount = Notification.Name("NSWorkspaceDidUnmountNotification")

    func start(nikonPrefix: String) {
        self.nikonPrefix = nikonPrefix
        refreshVolumes()

        let nc = NSWorkspace.shared.notificationCenter
        observers.append(nc.addObserver(forName: Self.didMount, object: nil, queue: .main) { [weak self] note in
            self?.volumeMounted(note)
        })
        observers.append(nc.addObserver(forName: Self.didUnmount, object: nil, queue: .main) { [weak self] note in
            self?.volumeUnmounted(note)
        })
    }

    func stop() {
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        observers.removeAll()
    }

    // MARK: - Eject

    func eject(url: URL) throws {
        try NSWorkspace.shared.unmountAndEjectDevice(at: url)
    }

    // MARK: - Volume status helpers

    func isVolumePresent(name: String) -> Bool {
        mountedVolumes.keys.contains { $0.hasPrefix(name) }
    }

    // MARK: - Private

    private func refreshVolumes() {
        let fm = FileManager.default
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        guard let contents = try? fm.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: [.volumeNameKey, .volumeIsEjectableKey],
            options: .skipsHiddenFiles
        ) else { return }

        var vols: [String: URL] = [:]
        for url in contents {
            vols[url.lastPathComponent] = url
        }
        mountedVolumes = vols
        updateNikonCard()
    }

    private func volumeMounted(_ note: Notification) {
        guard let url = note.userInfo?["NSWorkspaceVolumeURLKey"] as? URL else { return }
        mountedVolumes[url.lastPathComponent] = url
        updateNikonCard()
    }

    private func volumeUnmounted(_ note: Notification) {
        guard let url = note.userInfo?["NSWorkspaceVolumeURLKey"] as? URL else { return }
        mountedVolumes.removeValue(forKey: url.lastPathComponent)
        updateNikonCard()
    }

    private func updateNikonCard() {
        nikonCard = mountedVolumes.first { name, url in
            name.hasPrefix(nikonPrefix) && isEjectable(url: url)
        }?.value
    }

    private func isEjectable(url: URL) -> Bool {
        let vals = try? url.resourceValues(forKeys: [.volumeIsEjectableKey, .volumeIsRemovableKey])
        return vals?.volumeIsEjectable == true || vals?.volumeIsRemovable == true
    }
}
