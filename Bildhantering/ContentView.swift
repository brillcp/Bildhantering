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
                SettingsView(configStore: viewModel.configStore)

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
                ImportProgressView(job: job, engine: viewModel.ingestEngine)

            case .summary(let result):
                SummaryView(result: result) {
                    viewModel.ejectCard(url: result.cardURL)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 480)
    }
}
