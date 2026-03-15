import SwiftUI

struct ProjectPickerView: View {

    let card: CardInfo
    let projects: [String]
    let onSelect: (String?) -> Void  // nil = new job

    @State private var searchText = ""

    var filtered: [String] {
        searchText.isEmpty ? projects : projects.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Välj projekt")
                        .font(.title2.bold())
                    Text("Kort: \(card.name) · \(card.totalFileCount) filer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Nytt jobb") { onSelect(nil) }
                    .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            if projects.isEmpty {
                ContentUnavailableView(
                    "Inga projekt",
                    systemImage: "folder",
                    description: Text("Inga projekt hittades i BILD_verkstan. Klicka på \"Nytt jobb\" för att skapa ett.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filtered, id: \.self, selection: .constant(nil as String?)) { project in
                    Button(action: { onSelect(project) }) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.secondary)
                            Text(project)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .searchable(text: $searchText, placement: .sidebar)
            }
        }
    }
}
