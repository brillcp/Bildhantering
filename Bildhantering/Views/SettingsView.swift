import SwiftUI

struct SettingsView: View {

    @Bindable var configStore: ConfigStore

    var body: some View {
        Form {
            Section("Camera Card") {
                LabeledContent("Card name prefix") {
                    TextField("Nikon", text: $configStore.nikonCardPrefix)
                        .frame(width: 120)
                }
            }

            Section("Volumes") {
                VolumeRow(
                    label: "Cache / RAW_2",
                    name: configStore.cacheName,
                    action: { Task { await configStore.pickVolume(role: .cache) } }
                )
                VolumeRow(
                    label: "NAS / RAW_1",
                    name: configStore.nasName,
                    action: { Task { await configStore.pickVolume(role: .nas) } }
                )
                VolumeRow(
                    label: "BILD_verkstan",
                    name: configStore.bildVerkstanName,
                    action: { Task { await configStore.pickVolume(role: .bildVerkstan) } }
                )
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .padding()
    }
}

private struct VolumeRow: View {
    let label: String
    let name: String?
    let action: () -> Void

    var body: some View {
        LabeledContent(label) {
            HStack {
                Text(name ?? "Not configured")
                    .foregroundStyle(name != nil ? .primary : .secondary)
                Spacer()
                Button("Choose…", action: action)
            }
        }
    }
}
