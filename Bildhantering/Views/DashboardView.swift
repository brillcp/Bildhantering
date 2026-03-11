import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {

    @Bindable var viewModel: WorkflowViewModel
    @State private var isSelectingCard = false

    var body: some View {
        VStack(spacing: 0) {
            // Volume status bar
            HStack(spacing: 24) {
                VolumeStatusItem(label: "Cache", isOnline: viewModel.volumeStatus(for: viewModel.configStore.cacheName))
                VolumeStatusItem(label: "NAS", isOnline: viewModel.volumeStatus(for: viewModel.configStore.nasName))
                VolumeStatusItem(label: "BILD_verkstan", isOnline: viewModel.configStore.bildVerkstanName != nil)
                Spacer()
            }
            .padding()
            .background(.bar)

            Divider()

            Spacer()

            if let card = viewModel.volumeMonitor.nikonCard {
                CardReadyView(cardURL: card, onProceed: { isSelectingCard = true })
            } else {
                WaitingView()
            }

            Spacer()
        }
        .fileImporter(
            isPresented: $isSelectingCard,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.scanCard(url: url)
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
            Text("Waiting for Nikon card…")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Insert a CF card to begin import")
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
            Button("Start Import →", action: onProceed)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
