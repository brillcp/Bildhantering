import SwiftUI

struct ImportProgressView: View {

    let job: ImportJob
    let engine: IngestEngine
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .symbolEffect(.rotate, isActive: engine.progress < 1)

            VStack(spacing: 8) {
                Text("Importerar…")
                    .font(.title2.bold())
                Text("\(engine.filesProcessed) av \(engine.totalFiles) filer")
                    .foregroundStyle(.secondary)
                if !engine.currentFileName.isEmpty {
                    Text(engine.currentFileName)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            ProgressView(value: engine.progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 400)
                .padding(.horizontal)

            VStack(spacing: 4) {
                Text("Kort: \(job.card.name)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("\(job.fotodatum) · \(job.projNamn) · \(job.arbNamn)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Button("Avbryt", action: onCancel)
                .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
