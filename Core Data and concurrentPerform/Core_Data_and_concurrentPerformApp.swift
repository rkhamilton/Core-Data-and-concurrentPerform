//
//  Core_Data_and_concurrentPerformApp.swift
//  Core Data and concurrentPerform
//
//  Created by Ryan Hamilton on 1/31/22.
//

import SwiftUI
import CoreData

@main
struct Core_Data_and_concurrentPerformApp: App {
    @State var persistenceController: PersistenceController
    @State var viewModel: ViewModel

    init() {
        let persistenceController = PersistenceController.shared
        _persistenceController = State(initialValue: persistenceController)
        _viewModel = State(initialValue: ViewModel(persistenceController: persistenceController))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(persistenceController: persistenceController, viewModel: viewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
