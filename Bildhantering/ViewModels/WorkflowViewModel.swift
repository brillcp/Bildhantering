import Foundation
import AppKit

@Observable
final class WorkflowViewModel {

    var state: WorkflowState = .dashboard

    let configStore = ConfigStore()
    let volumeMonitor = VolumeMonitor()
    let ingestEngine = IngestEngine()

    init() {
        state = configStore.isConfigured ? .dashboard : .setup
    }

    // MARK: - Lifecycle

    func onAppear() {
        volumeMonitor.start(nikonPrefix: configStore.nikonCardPrefix)
    }

    func onDisappear() {
        volumeMonitor.stop()
    }

    // MARK: - Workflow transitions

    func settingsComplete() {
        state = configStore.isConfigured ? .dashboard : .setup
    }

    /// Called after the user has granted sandbox access via .fileImporter.
    func scanCard(url: URL) {
        guard case .dashboard = state else { return }
        _ = url.startAccessingSecurityScopedResource()
        do {
            let info = try CardScanner.scan(cardURL: url)
            cardAccessURL = url
            state = .cardDetected(info)
        } catch {
            url.stopAccessingSecurityScopedResource()
        }
    }

    private(set) var cardAccessURL: URL?

    func proceedToProjectPicker(card: CardInfo) {
        state = .projectPicker(card)
    }

    func projectSelected(_ name: String?, card: CardInfo) {
        state = .metadataForm(card, name)
    }

    func startImport(card: CardInfo, fotodatum: String, projNamn: String, arbNamn: String) {
        guard
            let cacheURL = configStore.accessURL(role: .cache),
            let nasURL = configStore.accessURL(role: .nas),
            let bildURL = configStore.accessURL(role: .bildVerkstan)
        else { return }

        configStore.lastFotodatum = fotodatum
        configStore.lastProjNamn = projNamn
        configStore.lastArbNamn = arbNamn

        let job = ImportJob(
            card: card,
            cacheURL: cacheURL,
            nasURL: nasURL,
            bildVerkstanURL: bildURL,
            fotodatum: fotodatum,
            projNamn: projNamn,
            arbNamn: arbNamn
        )
        state = .importing(job)

        Task {
            do {
                let result = try await ingestEngine.ingest(job: job)
                cacheURL.stopAccessingSecurityScopedResource()
                nasURL.stopAccessingSecurityScopedResource()
                bildURL.stopAccessingSecurityScopedResource()
                cardAccessURL?.stopAccessingSecurityScopedResource()
                cardAccessURL = nil
                state = .summary(result)
            } catch {
                cacheURL.stopAccessingSecurityScopedResource()
                nasURL.stopAccessingSecurityScopedResource()
                bildURL.stopAccessingSecurityScopedResource()
                cardAccessURL?.stopAccessingSecurityScopedResource()
                cardAccessURL = nil
                state = .dashboard
            }
        }
    }

    func ejectCard(url: URL) {
        cardAccessURL?.stopAccessingSecurityScopedResource()
        cardAccessURL = nil
        try? volumeMonitor.eject(url: url)
        state = configStore.isConfigured ? .dashboard : .setup
    }

    func returnToDashboard() {
        state = .dashboard
    }

    // MARK: - Volume helpers

    func volumeStatus(for name: String?) -> Bool {
        guard let name else { return false }
        return volumeMonitor.isVolumePresent(name: name)
    }

    var bildVerkstanProjects: [String] {
        guard let url = configStore.resolveURL(role: .bildVerkstan) else { return [] }
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        )) ?? []
        return contents
            .filter { item in
                let name = item.lastPathComponent
                guard !name.hasPrefix("_") else { return false }
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir)
                return isDir.boolValue
            }
            .map { $0.lastPathComponent }
            .sorted()
    }
}
