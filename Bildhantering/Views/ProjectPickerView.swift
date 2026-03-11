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
                    Text("Select Project")
                        .font(.title2.bold())
                    Text("Card: \(card.name) · \(card.totalFileCount) files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("New Job") { onSelect(nil) }
                    .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            if projects.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "folder",
                    description: Text("No projects found in BILD_verkstan. Click \"New Job\" to create one.")
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
