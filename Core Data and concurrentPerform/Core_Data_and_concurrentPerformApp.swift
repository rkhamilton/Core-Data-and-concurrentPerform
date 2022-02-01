//
//  Core_Data_and_concurrentPerformApp.swift
//  Core Data and concurrentPerform
//
//  Created by Ryan Hamilton on 1/31/22.
//

import SwiftUI

@main
struct Core_Data_and_concurrentPerformApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
