import SwiftUI

struct SetupView: View {

    @Bindable var configStore: ConfigStore
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                Text("Välkommen till Bildhantering")
                    .font(.title.bold())
                Text("Välj de tre mapparna nedan för att komma igång.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 32)

            Divider()

            // Folder configuration
            VStack(spacing: 0) {
                SetupRow(
                    icon: "internaldrive",
                    title: "Backup",
                    subtitle: "Lokal cachedisk",
                    name: configStore.cacheName,
                    action: { Task { await configStore.pickVolume(role: .cache) } }
                )
                Divider().padding(.leading, 52)
                SetupRow(
                    icon: "server.rack",
                    title: "NAS",
                    subtitle: "Nätverkslagring",
                    name: configStore.nasName,
                    action: { Task { await configStore.pickVolume(role: .nas) } }
                )
                Divider().padding(.leading, 52)
                SetupRow(
                    icon: "folder",
                    title: "Bildverkstan",
                    subtitle: "Projektbibliotek",
                    name: configStore.bildVerkstanName,
                    action: { Task { await configStore.pickVolume(role: .bildVerkstan) } }
                )
            }
            .background(.background)

            Divider()

            // Continue button
            HStack {
                Spacer()
                Button("Fortsätt →", action: onComplete)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!configStore.isConfigured)
            }
            .padding()
        }
    }
}

private struct SetupRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let name: String?
    let action: () -> Void

    var isConfigured: Bool { name != nil }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isConfigured ? Color.accentColor : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let name {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button(isConfigured ? "Ändra…" : "Välj…", action: action)
                .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
