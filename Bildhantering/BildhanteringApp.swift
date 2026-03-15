//
//  BildhanteringApp.swift
//  Bildhantering
//
//  Created by Viktor Gidlöf on 2026-03-09.
//

import SwiftUI

@main
struct BildhanteringApp: App {

    @State private var viewModel = WorkflowViewModel()

    var body: some Scene {
        Window("Bildhantering", id: "Main") {
            ContentView(viewModel: viewModel)
                .onAppear { viewModel.onAppear() }
                .onDisappear { viewModel.onDisappear() }
        }
        .defaultSize(width: 700, height: 520)
        .windowResizability(.contentSize)

        Settings {
            SettingsView(configStore: viewModel.configStore)
        }
    }
}
