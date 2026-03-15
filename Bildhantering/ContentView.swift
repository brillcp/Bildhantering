//
//  ContentView.swift
//  Bildhantering
//
//  Created by Viktor Gidlöf on 2026-03-09.
//

import SwiftUI

struct ContentView: View {

    @Bindable var viewModel: WorkflowViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .setup:
                SetupView(configStore: viewModel.configStore, onComplete: { viewModel.settingsComplete() })

            case .dashboard:
                DashboardView(viewModel: viewModel)

            case .cardDetected(let card):
                CardDetectedView(card: card) {
                    viewModel.proceedToProjectPicker(card: card)
                }

            case .projectPicker(let card):
                ProjectPickerView(
                    card: card,
                    projects: viewModel.bildVerkstanProjects,
                    onSelect: { project in viewModel.projectSelected(project, card: card) }
                )

            case .metadataForm(let card, let project):
                MetadataFormView(
                    card: card,
                    preselectedProject: project,
                    configStore: viewModel.configStore,
                    onStart: { fotodatum, projNamn, arbNamn in
                        viewModel.startImport(card: card, fotodatum: fotodatum, projNamn: projNamn, arbNamn: arbNamn)
                    }
                )

            case .importing(let job):
                ImportProgressView(job: job, engine: viewModel.ingestEngine, onCancel: { viewModel.cancelImport() })

            case .summary(let result):
                SummaryView(result: result) {
                    viewModel.ejectCard(url: result.cardURL)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 480)
        .safeAreaInset(edge: .top, spacing: 0) {
            if viewModel.canGoBack {
                HStack {
                    Button(action: { viewModel.goBack() }) {
                        Label("Tillbaka", systemImage: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                Divider()
            }
        }
    }
}
