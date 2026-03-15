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

    /// Extracts the sequence number from a filename by finding the last run of 4+ digits.
    /// e.g. "DSC_0042.NEF" → "0042", "_DSC0042.NEF" → "0042"
    nonisolated static func sequenceNumber(from filename: String) -> String {
        let name = (filename as NSString).deletingPathExtension
        let regex = try! NSRegularExpression(pattern: "\\d{4,}")
        let nsName = name as NSString
        let matches = regex.matches(in: name, range: NSRange(location: 0, length: nsName.length))
        if let last = matches.last {
            return String(nsName.substring(with: last.range).suffix(4))
        }
        return "0000"
    }

    nonisolated static func isImageFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.uppercased()
        return ["NEF", "JPG", "JPEG", "AVI", "WAV", "DNG", "PNG"].contains(ext)
    }
}
