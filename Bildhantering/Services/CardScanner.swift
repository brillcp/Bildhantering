import Foundation

enum CardScanError: LocalizedError {
    case dcimNotFound
    case cardEmpty

    var errorDescription: String? {
        switch self {
        case .dcimNotFound: return "No DCIM folder found on the card."
        case .cardEmpty: return "The card contains no image folders."
        }
    }
}

struct CardScanner {

    private static let ignoredFolders = ["MISC", "NIKON"]

    nonisolated static func scan(cardURL: URL) throws -> CardInfo {
        let fm = FileManager.default
        let dcim = cardURL.appendingPathComponent("DCIM")

        guard fm.fileExists(atPath: dcim.path) else {
            throw CardScanError.dcimNotFound
        }

        let allFolders = (try? fm.contentsOfDirectory(at: dcim, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)) ?? []

        let imageFolders = allFolders.filter { url in
            let name = url.lastPathComponent.uppercased()
            guard !ignoredFolders.contains(name) else { return false }
            var isDir: ObjCBool = false
            fm.fileExists(atPath: url.path, isDirectory: &isDir)
            return isDir.boolValue
        }.sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !imageFolders.isEmpty else {
            throw CardScanError.cardEmpty
        }

        var totalFiles = 0
        var firstSeqNr = ""
        var lastSeqNr = ""

        for folder in imageFolders {
            let files = (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
            let imageFiles = files.filter { isImageFile($0) }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            totalFiles += imageFiles.count

            if let first = imageFiles.first, firstSeqNr.isEmpty {
                firstSeqNr = sequenceNumber(from: first.lastPathComponent)
            }
            if let last = imageFiles.last {
                lastSeqNr = sequenceNumber(from: last.lastPathComponent)
            }
        }

        return CardInfo(
            url: cardURL,
            name: cardURL.lastPathComponent,
            dcimFolders: imageFolders,
            totalFileCount: totalFiles,
            firstSeqNr: firstSeqNr,
            lastSeqNr: lastSeqNr
        )
    }

    // MARK: - Helpers

    /// Extracts chars -8 thru -5 from filename (Nikon sequence number).
    /// e.g. "DSC_0042.NEF" → "0042"
    nonisolated static func sequenceNumber(from filename: String) -> String {
        guard filename.count >= 8 else { return "0000" }
        let start = filename.index(filename.endIndex, offsetBy: -8)
        let end = filename.index(filename.endIndex, offsetBy: -4)
        return String(filename[start..<end])
    }

    nonisolated static func isImageFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.uppercased()
        return ["NEF", "JPG", "JPEG", "AVI", "WAV", "DNG", "PNG"].contains(ext)
    }
}
