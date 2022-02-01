//
//  ViewModel.swift
//  Core Data and concurrentPerform
//
//  Created by Ryan Hamilton on 1/31/22.
//

import SwiftUI
import CoreData

final class ViewModel: ObservableObject {
    private let persistenceController: PersistenceController
    private let numberOfIterationsForWork: Int = 10000

    @Published var serialUsingCoreData: Int
    @Published var serialUsingArray: Int
    @Published var concurrentPerformUsingCoreData: Int
    @Published var concurrentPerformUsingArray: Int

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.serialUsingCoreData = 0
        self.serialUsingArray = 0
        self.concurrentPerformUsingCoreData = 0
        self.concurrentPerformUsingArray = 0
    }

    func calculateSerialUsingCoreData(_ items: [Item]) {
        let startTime = CFAbsoluteTimeGetCurrent()
        for item in items {
            // create copy of the sourceItem in a childContext so we don't mutate the original
            let parentContext = item.managedObjectContext
            let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            childContext.parent = parentContext
            let childObject: Item = try! childContext.existingObject(with: item.objectID) as! Item

            _ = timeConsumingWork(managedObject: childObject)
        }
        serialUsingCoreData = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        print("serialUsingCoreData: \(serialUsingCoreData)")
    }

    func calculateSerialUsingArray(_ items: [Item]) {
        let itemsAsDoubles: [Double] = items.map {$0.valueMO}
        let startTime = CFAbsoluteTimeGetCurrent()
        for item in itemsAsDoubles {
            _ = timeConsumingWork(inputValue: item)
        }
        serialUsingArray = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        print("serialUsingArray: \(serialUsingArray)")
    }

    func calculateConcurrentPerformUsingCoreData(_ items: [Item]) {
        let startTime = CFAbsoluteTimeGetCurrent()

        DispatchQueue.concurrentPerform(iterations: items.count-1) { index in
            // create copy of the sourceItem in a childContext so we don't mutate the original
            let sourceItem: Item = items[index]
            guard let parentContext = sourceItem.managedObjectContext else {
                // we shouldn't be passing a managed object without a context to this init...
                fatalError("Attempting to edit a managed object that's not associated with a context")
            }

            let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            childContext.parent = parentContext

            childContext.performAndWait {
                guard let childObject = try? childContext.existingObject(with: sourceItem.objectID) as? Item else {
                    fatalError("Attempting to edit a managed object that's not associated with a context")
                }
                _ = timeConsumingWork(managedObject: childObject)
            }
        }
        concurrentPerformUsingCoreData = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        print("concurrentPerformUsingCoreData: \(concurrentPerformUsingCoreData)")
    }

    func calculateConcurrentPerformUsingArray(_ items: [Item]) {
        let itemsAsDoubles: [Double] = items.map {$0.valueMO}
        let startTime = CFAbsoluteTimeGetCurrent()

        let concurrentQueue = DispatchQueue.init(label: "ConcurrentPerformUsingArray", qos: .userInitiated, attributes: .concurrent)

        concurrentQueue.async {
            DispatchQueue.concurrentPerform(iterations: itemsAsDoubles.count) { index in
                _ = self.timeConsumingWork(inputValue: itemsAsDoubles[index])
            }

            DispatchQueue.main.async {
                self.concurrentPerformUsingArray = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
                print("concurrentPerformUsingArray: \(self.concurrentPerformUsingArray)")
            }
        }
    }


    func timeConsumingWork(inputValue: Double) -> Double {
        var interimResult: Double = inputValue
        for _ in 0..<numberOfIterationsForWork {
            interimResult = pow(inputValue,2)
            interimResult = inputValue + Double.random(in: -1...1)
            interimResult = inputValue.squareRoot()
            interimResult = inputValue + Double.random(in: -1...1)
        }
        return interimResult
    }

    func timeConsumingWork(managedObject: Item) -> Double {
        let interimResult: Item = managedObject
        for _ in 0..<numberOfIterationsForWork {
            interimResult.valueMO = pow(interimResult.valueMO,2)
            interimResult.valueMO = interimResult.valueMO + Double.random(in: -1...1)
            interimResult.valueMO = interimResult.valueMO.squareRoot()
            interimResult.valueMO = interimResult.valueMO + Double.random(in: -1...1)
        }
        return interimResult.valueMO
    }
}

