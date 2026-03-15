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
                    Text("Jobbdetaljer")
                        .font(.title2.bold())
                    Text("Kort: \(card.name) · \(card.totalFileCount) filer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Fotodatum") {
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                    Text("Filprefix: \(fotodatum)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Namngivning") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Projekt (projNamn)").font(.caption).foregroundStyle(.secondary)
                        TextField("t.ex. KarlssonBrollop", text: $projNamn)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Arbetsnamn (arbNamn)").font(.caption).foregroundStyle(.secondary)
                        TextField("t.ex. Ceremoni", text: $arbNamn)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("Förhandsgranskning") {
                    let first = card.firstSeqNr.isEmpty ? "0001" : card.firstSeqNr
                    let proj = projNamn.isEmpty ? "projektnamn" : projNamn
                    let arb = arbNamn.isEmpty ? "arbnamn" : arbNamn
                    Text("\(fotodatum)_\(first)_\(proj)_\(arb)_ErS.NEF")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("\(fotodatum)_\(card.lastSeqNr.isEmpty ? "0002" : card.lastSeqNr)_\(proj)_\(arb)_ErS.NEF")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Starta import") {
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
