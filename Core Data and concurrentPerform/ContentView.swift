//
//  ContentView.swift
//  Core Data and concurrentPerform
//
//  Created by Ryan Hamilton on 1/31/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let persistenceController: PersistenceController
    @ObservedObject var viewModel: ViewModel

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.valueMO, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
         ScrollView {
            List {
                ForEach(items) { item in
                    Text("\(item.valueMO, specifier: "%.2f")")
                }
                .onDelete(perform: deleteItems)
            }
            .frame(width: 300, height: 300, alignment: .leading)
            .padding()
            resultsView
                .padding()
            Button(role: .none) {
                addItem()
            } label: {
                Text("Add 10 Items to Calculate")
            }
            .buttonStyle(.automatic)
            .padding()
            Button(role: .none) {
                viewModel.calculateSerialUsingArray(items.map {$0})
                viewModel.calculateConcurrentPerformUsingArray(items.map {$0})
                viewModel.calculateSerialUsingCoreData(items.map {$0})
//                viewModel.calculateConcurrentPerformUsingCoreData(items.map {$0})
            } label: {
                Text("Calculate All")
            }
            .buttonStyle(.automatic)
        }


    }

    private func addItem() {
        withAnimation {
            for _ in 0..<10 {
                let newItem = Item(context: viewContext)
                newItem.valueMO = Double.random(in: 0...1.0)
            }
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private var resultsView: some View {
        VStack(alignment: .leading) {
            Text("Serial Function with Array \(viewModel.serialUsingArray) ms")
            Text("Serial Function with Core Data \(viewModel.serialUsingCoreData) ms")
            Text("Concurrent Perform with Array \(viewModel.concurrentPerformUsingArray) ms")
            Text("Concurrent Perform with Core Data \(viewModel.concurrentPerformUsingCoreData) ms")
        }
    }
}

private let itemFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 3
    formatter.maximumFractionDigits = 3
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static let persistenceController: PersistenceController = PersistenceController.preview
    static var previews: some View {
        ContentView(persistenceController: persistenceController, viewModel: ViewModel(persistenceController: persistenceController))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
