import SwiftUI

struct MetadataFormView: View {

    let card: CardInfo
    let preselectedProject: String?
    let configStore: ConfigStore
    let onStart: (String, String, String) -> Void  // fotodatum, projNamn, arbNamn

    @State private var date: Date
    @State private var projNamn: String
    @State private var arbNamn: String

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyMMdd"
        return f
    }()

    init(card: CardInfo, preselectedProject: String?, configStore: ConfigStore, onStart: @escaping (String, String, String) -> Void) {
        self.card = card
        self.preselectedProject = preselectedProject
        self.configStore = configStore
        self.onStart = onStart

        // Pre-fill from last-used or selected project
        let savedDate = configStore.lastFotodatum
        _date = State(initialValue: Self.parseDate(savedDate) ?? Date())
        _projNamn = State(initialValue: preselectedProject ?? configStore.lastProjNamn)
        _arbNamn = State(initialValue: configStore.lastArbNamn)
    }

    private var fotodatum: String { dateFormatter.string(from: date) }

    private var isValid: Bool {
        !projNamn.trimmingCharacters(in: .whitespaces).isEmpty &&
        !arbNamn.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Job Details")
                        .font(.title2.bold())
                    Text("Card: \(card.name) · \(card.totalFileCount) files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Photo Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Text("File prefix: \(fotodatum)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Naming") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Project (projNamn)").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. KarlssonBrollop", text: $projNamn)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Working name (arbNamn)").font(.caption).foregroundStyle(.secondary)
                        TextField("e.g. Ceremoni", text: $arbNamn)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("Preview") {
                    Text("\(fotodatum)_\(card.firstSeqNr.isEmpty ? "0001" : card.firstSeqNr)_\(arbNamn.isEmpty ? "arbnamn" : arbNamn)_ErS.NEF")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Start Import") {
                    onStart(fotodatum, projNamn.trimmingCharacters(in: .whitespaces), arbNamn.trimmingCharacters(in: .whitespaces))
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
    }

    private static func parseDate(_ string: String) -> Date? {
        guard string.count == 6 else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyMMdd"
        return f.date(from: string)
    }
}
