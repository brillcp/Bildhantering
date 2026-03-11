import SwiftUI

struct SummaryView: View {

    let result: ImportResult
    let onEject: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: result.errors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(result.errors.isEmpty ? Color.green : Color.yellow)

            Text(result.errors.isEmpty ? "Import Complete" : "Import Finished with Errors")
                .font(.title2.bold())

            // Stats
            HStack(spacing: 32) {
                StatItem(value: "\(result.filesCopied)", label: "Files copied")
                StatItem(value: "\(result.cacheFolders.count)", label: "Cache folder(s)")
                StatItem(value: "\(result.nasFolders.count)", label: "NAS folder(s)")
            }

            // Destination folders
            if let first = result.cacheFolders.first {
                PathLabel(prefix: "Cache", url: first)
            }
            if let first = result.nasFolders.first {
                PathLabel(prefix: "NAS", url: first)
            }

            // Errors
            if !result.errors.isEmpty {
                GroupBox("Errors (\(result.errors.count))") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(result.errors, id: \.self) { error in
                                Text("• \(error)")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                }
                .padding(.horizontal)
            }

            Button("Eject Card & Finish") { onEject() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PathLabel: View {
    let prefix: String
    let url: URL

    var body: some View {
        HStack(spacing: 6) {
            Text(prefix + ":")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(url.lastPathComponent)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
