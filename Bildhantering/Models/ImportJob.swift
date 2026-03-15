import Foundation

struct CardInfo {
    let url: URL
    let name: String
    let dcimFolders: [URL]
    let totalFileCount: Int
    let firstSeqNr: String
    let lastSeqNr: String
}

struct ImportJob {
    let card: CardInfo
    let cacheURL: URL
    let nasURL: URL
    let bildVerkstanURL: URL
    let fotodatum: String   // YYMMDD
    let projNamn: String
    let arbNamn: String
    let signature: String
}

struct ImportResult {
    let filesCopied: Int
    let cacheFolders: [URL]
    let nasFolders: [URL]
    let errors: [String]
    let cardURL: URL
}
