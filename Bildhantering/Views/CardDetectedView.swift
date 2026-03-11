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

                Text("\(card.totalFileCount) files in \(card.dcimFolders.count) folder(s)")
                    .foregroundStyle(.secondary)

                if !card.firstSeqNr.isEmpty {
                    Text("Sequence \(card.firstSeqNr) – \(card.lastSeqNr)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Button("Select Project →", action: onProceed)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
