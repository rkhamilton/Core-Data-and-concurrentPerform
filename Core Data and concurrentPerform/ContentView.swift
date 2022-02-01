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

    @FetchRequest var items: FetchedResults<Item>

    init(persistenceController: PersistenceController, viewModel: ViewModel) {
        self.persistenceController = persistenceController
        self.viewModel = viewModel
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.valueMO, ascending: true)]
        _items = FetchRequest(fetchRequest: request)
    }

    var body: some View {
         ScrollView {
            List {
                ForEach(items) { item in
                    Text("\(item.valueMO, specifier: "%.2f")")
                }
                .onDelete(perform: deleteItems)
            }
            .frame(width: 300, height: 100, alignment: .leading)
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
                viewModel.calculateSerialUsingDouble(items.first!)
            } label: {
                Text("calculateSerialUsingDouble")
            }
            .buttonStyle(.automatic)
            .padding()
             Button(role: .none) {
                 viewModel.calculateConcurrentPerformUsingDouble(items.first!)
             } label: {
                 Text("calculateConcurrentPerformUsingDouble")
             }
             .buttonStyle(.automatic)
             .padding()
             Button(role: .none) {
                 viewModel.calculateSerialUsingCoreData(items.first!)
             } label: {
                 Text("calculateSerialUsingCoreData")
             }
             .buttonStyle(.automatic)
             .padding()
             Button(role: .none) {
                 viewModel.calculateConcurrentPerformUsingCoreData(items.first!)
             } label: {
                 Text("calculateConcurrentPerformUsingCoreData")
             }
             .buttonStyle(.automatic)
             .padding()
             Button(role: .none) {
                 viewModel.calculateSerialUsingDouble(items.first!)
                 viewModel.calculateConcurrentPerformUsingDouble(items.first!)
                 viewModel.calculateSerialUsingCoreData(items.first!)
                 viewModel.calculateConcurrentPerformUsingCoreData(items.first!)
             } label: {
                 Text("Calculate All at Once")
             }
             .buttonStyle(.automatic)
             .padding()
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
            Text("Serial Double \(viewModel.serialUsingDouble) ms \(viewModel.serialUsingDoubleValue)")
            Text("Serial Core Data \(viewModel.serialUsingCoreData) ms \(viewModel.serialUsingCoreDataValue)")
            Text("Concurrent Double \(viewModel.concurrentPerformUsingDouble) ms \(viewModel.concurrentPerformUsingDoubleValue)")
            Text("Concurrent Core Data \(viewModel.concurrentPerformUsingCoreData) ms \(viewModel.concurrentPerformUsingCoreDataValue)")
            
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
