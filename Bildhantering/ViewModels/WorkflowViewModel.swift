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

    func scanCard(url: URL) {
        guard case .dashboard = state else { return }
        do {
            let info = try CardScanner.scan(cardURL: url)
            state = .cardDetected(info)
        } catch {
            // Card not ready or no images — stay on dashboard
        }
    }

    func proceedToProjectPicker(card: CardInfo) {
        state = .projectPicker(card)
    }

    func projectSelected(_ name: String?, card: CardInfo) {
        state = .metadataForm(card, name)
    }

    func startImport(card: CardInfo, fotodatum: String, projNamn: String, arbNamn: String) {
        guard
            let cacheURL = configStore.resolveURL(role: .cache),
            let nasURL = configStore.resolveURL(role: .nas),
            let bildURL = configStore.resolveURL(role: .bildVerkstan)
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
                state = .summary(result)
            } catch {
                let failed = ImportResult(
                    filesCopied: 0,
                    cacheFolders: [],
                    nasFolders: [],
                    errors: [error.localizedDescription],
                    cardURL: job.card.url
                )
                state = .summary(failed)
            }
        }
    }

    func ejectCard(url: URL) {
        try? volumeMonitor.eject(url: url)
        state = configStore.isConfigured ? .dashboard : .setup
    }

    func returnToDashboard() {
        state = .dashboard
    }

    func resetToSetup() {
        configStore.reset()
        state = .setup
    }

    var canGoBack: Bool {
        switch state {
        case .cardDetected, .projectPicker, .metadataForm:
            return true
        default:
            return false
        }
    }

    func goBack() {
        switch state {
        case .cardDetected:
            state = .dashboard
        case .projectPicker(let card):
            state = .cardDetected(card)
        case .metadataForm(let card, _):
            state = .projectPicker(card)
        default:
            break
        }
    }

    // MARK: - Volume helpers

    func volumeStatus(for role: VolumeRole) -> Bool {
        _ = volumeMonitor.mountedVolumes  // register dependency so dots update on mount/unmount
        guard let url = configStore.resolveURL(role: role) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    var bildVerkstanProjects: [String] {
        guard let url = configStore.resolveURL(role: .bildVerkstan) else { return [] }
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
