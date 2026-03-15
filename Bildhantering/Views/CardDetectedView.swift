import SwiftUI

struct CardDetectedView: View {

    let card: CardInfo
    let onProceed: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sdcard.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text(card.name)
                    .font(.title.bold())

                Text("\(card.totalFileCount) filer i \(card.dcimFolders.count) mapp(ar)")
                    .foregroundStyle(.secondary)

                if !card.firstSeqNr.isEmpty {
                    Text("Sekvens \(card.firstSeqNr) – \(card.lastSeqNr)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Button("Välj projekt →", action: onProceed)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
