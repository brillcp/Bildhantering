import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {

    @Bindable var viewModel: WorkflowViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Volume status bar
            HStack(spacing: 24) {
                VolumeStatusItem(label: "Backup", isOnline: viewModel.volumeStatus(for: .cache))
                VolumeStatusItem(label: "NAS", isOnline: viewModel.volumeStatus(for: .nas))
                VolumeStatusItem(label: "Bildverkstan", isOnline: viewModel.volumeStatus(for: .bildVerkstan))
                Spacer()
            }
            .padding()
            .background(.bar)

            Divider()

            Spacer()

            if let card = viewModel.volumeMonitor.nikonCard {
                CardReadyView(cardURL: card, onProceed: { viewModel.scanCard(url: card) })
            } else {
                WaitingView()
            }

            Spacer()
        }
        .onChange(of: viewModel.volumeMonitor.nikonCard) { old, new in
            if old == nil, let card = new {
                viewModel.scanCard(url: card)
            }
        }
    }
}

// MARK: - Sub-views

private struct VolumeStatusItem: View {
    let label: String
    let isOnline: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isOnline ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct WaitingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sdcard")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Väntar på Nikon-kort…")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Sätt i ett CF-kort för att börja importen")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct CardReadyView: View {
    let cardURL: URL
    let onProceed: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sdcard.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text(cardURL.lastPathComponent)
                .font(.title2.bold())
            Button("Starta import →", action: onProceed)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
