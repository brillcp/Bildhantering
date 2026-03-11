import Foundation
import AppKit

@Observable
final class IngestEngine {

    var progress: Double = 0
    var filesProcessed: Int = 0
    var totalFiles: Int = 0
    var currentFileName: String = ""
    var errors: [String] = []

    // MARK: - Main entry point

    func ingest(job: ImportJob) async throws -> ImportResult {
        errors = []
        filesProcessed = 0
        totalFiles = job.card.totalFileCount
        progress = 0

        var allCacheFolders: [URL] = []
        var allNasFolders: [URL] = []
        var filesCopied = 0

        for dcimFolder in job.card.dcimFolders {
            let result = try await ingestFolder(dcimFolder, job: job)
            allCacheFolders.append(contentsOf: result.cacheFolders)
            allNasFolders.append(contentsOf: result.nasFolders)
            filesCopied += result.filesCopied
        }

        return ImportResult(
            filesCopied: filesCopied,
            cacheFolders: allCacheFolders,
            nasFolders: allNasFolders,
            errors: errors,
            cardURL: job.card.url
        )
    }

    // MARK: - Per-folder ingestion

    private func ingestFolder(_ folder: URL, job: ImportJob) async throws -> ImportResult {
        let fm = FileManager.default

        let files = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
        let imageFiles = files.filter { CardScanner.isImageFile($0) }.sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !imageFiles.isEmpty else {
            return ImportResult(filesCopied: 0, cacheFolders: [], nasFolders: [], errors: [], cardURL: job.card.url)
        }

        // Step 1: Unlock files
        unlockFiles(imageFiles)

        // Step 2: Calculate sequence range for this folder
        let firstSeq = CardScanner.sequenceNumber(from: imageFiles.first!.lastPathComponent)
        let lastSeq = CardScanner.sequenceNumber(from: imageFiles.last!.lastPathComponent)

        // Step 3: Rename files on the card
        let renamedFiles = try await Task.detached(priority: .utility) { [job] in
            try Self.renameFiles(imageFiles, job: job)
        }.value

        // Step 4: Create cache folder and copy
        let cacheFolderName = "\(job.fotodatum)_\(job.arbNamn)_\(firstSeq)-\(lastSeq)_\(job.projNamn)_RAW_2"
        let cacheFolder = job.cacheURL.appendingPathComponent(cacheFolderName)
        try createFolder(at: cacheFolder)

        let copiedToCache = try await copyFiles(renamedFiles, to: cacheFolder)

        // Step 5: Create NAS session folder
        let sessionFolderName = "\(job.fotodatum)_\(firstSeq)-\(lastSeq)_\(job.projNamn)_\(job.arbNamn)"
        let nasSessionFolder = job.nasURL.appendingPathComponent(sessionFolderName)
        try createFolder(at: nasSessionFolder)

        // Step 6: Create BILD_verkstan folder structure + alias
        let bildProjFolder = job.bildVerkstanURL.appendingPathComponent(job.projNamn)
        let bildArbFolder = bildProjFolder.appendingPathComponent(job.arbNamn)
        try createFolder(at: bildProjFolder)
        try createFolder(at: bildArbFolder)
        try createAlias(at: bildArbFolder.appendingPathComponent(sessionFolderName), pointingTo: nasSessionFolder)

        // Step 7: Copy from cache to NAS
        let nasFiles = (try? fm.contentsOfDirectory(at: cacheFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
        let nasImageFiles = nasFiles.filter { CardScanner.isImageFile($0) }
        _ = try await copyFiles(nasImageFiles, to: nasSessionFolder)

        return ImportResult(
            filesCopied: copiedToCache,
            cacheFolders: [cacheFolder],
            nasFolders: [nasSessionFolder],
            errors: [],
            cardURL: job.card.url
        )
    }

    // MARK: - File operations

    private nonisolated static func renameFiles(_ files: [URL], job: ImportJob) throws -> [URL] {
        var renamed: [URL] = []
        for file in files {
            let original = file.lastPathComponent
            let seqNr = CardScanner.sequenceNumber(from: original)
            let ext = file.pathExtension.uppercased()
            let newName = "\(job.fotodatum)_\(seqNr)_\(job.arbNamn)_ErS.\(ext)"
            let dest = file.deletingLastPathComponent().appendingPathComponent(newName)
            if !FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.moveItem(at: file, to: dest)
            }
            renamed.append(dest)
        }
        return renamed
    }

    private func copyFiles(_ files: [URL], to destination: URL) async throws -> Int {
        let fm = FileManager.default
        var copied = 0

        for file in files {
            currentFileName = file.lastPathComponent
            let dest = destination.appendingPathComponent(file.lastPathComponent)
            do {
                if fm.fileExists(atPath: dest.path) {
                    try fm.removeItem(at: dest)
                }
                try await Task.detached(priority: .utility) {
                    try fm.copyItem(at: file, to: dest)
                }.value
                copied += 1
            } catch {
                errors.append("Failed to copy \(file.lastPathComponent): \(error.localizedDescription)")
            }
            filesProcessed += 1
            progress = totalFiles > 0 ? Double(filesProcessed) / Double(totalFiles) : 0
        }
        return copied
    }

    private func unlockFiles(_ files: [URL]) {
        for file in files {
            var attrs = (try? FileManager.default.attributesOfItem(atPath: file.path)) ?? [:]
            attrs[.immutable] = false
            try? FileManager.default.setAttributes(attrs, ofItemAtPath: file.path)
        }
    }

    private func createFolder(at url: URL) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func createAlias(at aliasURL: URL, pointingTo targetURL: URL) throws {
        guard !FileManager.default.fileExists(atPath: aliasURL.path) else { return }
        let bookmarkData = try targetURL.bookmarkData(
            options: .suitableForBookmarkFile,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        try URL.writeBookmarkData(bookmarkData, to: aliasURL)
    }
}
