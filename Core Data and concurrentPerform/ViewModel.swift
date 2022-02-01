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
    private let numberOfInnerLoopIterations: Int = 100000
    private let numberOfOuterLoopIterations: Int = 20

    @Published var serialUsingCoreData: Int
    @Published var serialUsingDouble: Int
    @Published var concurrentPerformUsingCoreData: Int
    @Published var concurrentPerformUsingDouble: Int

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.serialUsingCoreData = 0
        self.serialUsingDouble = 0
        self.concurrentPerformUsingCoreData = 0
        self.concurrentPerformUsingDouble = 0
    }

    func calculateSerialUsingCoreData(_ item: Item) {
        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<numberOfOuterLoopIterations {
            // create copy of the sourceItem in a childContext so we don't mutate the original
            let parentContext = item.managedObjectContext
            let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            childContext.parent = parentContext
            let childObject: Item = try! childContext.existingObject(with: item.objectID) as! Item

            _ = timeConsumingWork(managedObject: childObject)
        }
        let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        serialUsingCoreData = elapsedTime
        print("serialUsingCoreData: \(elapsedTime)")
    }

    func calculateSerialUsingDouble(_ item: Item) {
        let itemAsDoubles: Double = item.valueMO
        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<numberOfOuterLoopIterations {
            _ = timeConsumingWork(inputValue: itemAsDoubles)
        }
        let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        serialUsingDouble = elapsedTime
        print("serialUsingArray: \(elapsedTime)")
    }

    func calculateConcurrentPerformUsingDouble(_ item: Item) {
        let itemAsDoubles: Double = item.valueMO
        let startTime = CFAbsoluteTimeGetCurrent()

        let concurrentQueue = DispatchQueue.init(label: "ConcurrentPerformUsingArray", qos: .userInitiated, attributes: .concurrent)

        concurrentQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.numberOfOuterLoopIterations) { index in
                _ = self.timeConsumingWork(inputValue: itemAsDoubles)
            }
            DispatchQueue.main.async {
                let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
                self.concurrentPerformUsingDouble = elapsedTime
                print("concurrentPerformUsingDouble: \(elapsedTime)")
            }
        }
    }

    func calculateConcurrentPerformUsingCoreData(_ item: Item) {
        let startTime = CFAbsoluteTimeGetCurrent()

        let concurrentQueue = DispatchQueue.init(label: "ConcurrentPerformUsingArray", qos: .userInitiated, attributes: .concurrent)

        concurrentQueue.async {
            DispatchQueue.concurrentPerform(iterations: self.numberOfOuterLoopIterations) { index in
                // create copy of the sourceItem in a childContext so we don't mutate the original
                let sourceItem: Item = item
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
                    _ = self.timeConsumingWork(managedObject: childObject)
                }
            }
            DispatchQueue.main.async {
                let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
                self.concurrentPerformUsingCoreData = elapsedTime
                print("concurrentPerformUsingCoreData: \(elapsedTime)")
            }
        }
    }




    func timeConsumingWork(inputValue: Double) -> Double {
        var interimResult: Double = inputValue
        for _ in 0..<numberOfInnerLoopIterations {
            interimResult = pow(inputValue,2)
            interimResult = inputValue + Double.random(in: -1...1)
            interimResult = inputValue.squareRoot()
            interimResult = inputValue + Double.random(in: -1...1)
        }
        return interimResult
    }

    func timeConsumingWork(managedObject: Item) -> Double {
        let interimResult: Item = managedObject
        for _ in 0..<numberOfInnerLoopIterations {
            interimResult.valueMO = pow(interimResult.valueMO,2)
            interimResult.valueMO = interimResult.valueMO + Double.random(in: -1...1)
            interimResult.valueMO = interimResult.valueMO.squareRoot()
            interimResult.valueMO = interimResult.valueMO + Double.random(in: -1...1)
        }
        return interimResult.valueMO
    }

}

