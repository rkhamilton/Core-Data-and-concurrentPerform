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
            Text("This app tests the performance of structs and core data managed objects within a hot inner loop that is calculating pi. This example runs the same algorithm with one of two internal data structures: a struct with a double attribute, and a core data NSManagedObject with a double attribute. It also runs in either a simple serial queue, or in parallel using concurrentPerform. I find here that using the Core Data object takes 30-fold longer than using the struct.")
                .font(.footnote)
                .padding()

            Text("Does an item exist in the store? If not add one.")
            if let value = items.first?.valueMO {
                Text("Item: \(value, specifier: "%.2f")")
            } else {
                VStack {
                    Text("Add an item")
                    Button(role: .none) {
                        addItem()
                    } label: {
                        Text("Add Item to Core Data store")
                    }
                    .buttonStyle(.automatic)
                }
            }
            resultsView
                .padding()
            VStack(alignment: .leading) {
                Text("Calculation Methods")
                Button(role: .none) {
                    viewModel.calculateSerialUsingDouble(items.first!)
                } label: {
                    Text("Serial Struct")
                }
                .buttonStyle(.automatic)
                .padding()
                Button(role: .none) {
                    viewModel.calculateConcurrentPerformUsingDouble(items.first!)
                } label: {
                    Text("concurrentPerform Struct")
                }
                .buttonStyle(.automatic)
                .padding()
                Button(role: .none) {
                    viewModel.calculateSerialUsingCoreData(items.first!)
                } label: {
                    Text("Serial Core Data")
                }
                .buttonStyle(.automatic)
                .padding()
                Button(role: .none) {
                    viewModel.calculateConcurrentPerformUsingCoreData(items.first!)
                } label: {
                    Text("concurrentPerform Core Data")
                }
                .buttonStyle(.automatic)
                .padding()
            }

        }


    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.valueMO = Double.random(in: 0...1.0)
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
            Text("Results").bold()
            Text("Serial Struct \(viewModel.serialUsingDouble) ms Pi: \(viewModel.serialUsingDoubleValue)")
            Text("Concurrent Struct \(viewModel.concurrentPerformUsingDouble) ms Pi: \(viewModel.concurrentPerformUsingDoubleValue)")
            Text("Serial Core Data \(viewModel.serialUsingCoreData) ms Pi: \(viewModel.serialUsingCoreDataValue)")
            Text("Concurrent Core Data \(viewModel.concurrentPerformUsingCoreData) ms Pi: \(viewModel.concurrentPerformUsingCoreDataValue)")
            
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
