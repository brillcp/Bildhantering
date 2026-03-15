import SwiftUI

struct SettingsView: View {

    @Bindable var configStore: ConfigStore
    var onComplete: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Kamerakort") {
                    LabeledContent("Kortnamnsprefix") {
                        TextField("Nikon", text: $configStore.nikonCardPrefix)
                            .frame(width: 120)
                    }
                }

                Section("Volymer") {
                    VolumeRow(
                        label: "Backup",
                        name: configStore.cacheName,
                        action: { Task { await configStore.pickVolume(role: .cache) } }
                    )
                    VolumeRow(
                        label: "NAS",
                        name: configStore.nasName,
                        action: { Task { await configStore.pickVolume(role: .nas) } }
                    )
                    VolumeRow(
                        label: "Bildverkstan",
                        name: configStore.bildVerkstanName,
                        action: { Task { await configStore.pickVolume(role: .bildVerkstan) } }
                    )
                }
            }
            .formStyle(.grouped)

            if let onComplete {
                Divider()
                HStack {
                    Spacer()
                    Button("Fortsätt →", action: onComplete)
                        .buttonStyle(.borderedProminent)
                        .disabled(!configStore.isConfigured)
                }
                .padding()
            }
        }
        .frame(width: 400)
    }
}

private struct VolumeRow: View {
    let label: String
    let name: String?
    let action: () -> Void

    var body: some View {
        LabeledContent(label) {
            HStack {
                Text(name ?? "Ej konfigurerad")
                    .foregroundStyle(name != nil ? .primary : .secondary)
                Spacer()
                Button("Välj…", action: action)
            }
        }
    }
}
