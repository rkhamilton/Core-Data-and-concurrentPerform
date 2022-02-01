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
    private let numberOfInnerLoopIterations: Int = 5_000_00
    private let numberOfOuterLoopIterations: Int = 200

    @Published var serialUsingCoreData: Int
    @Published var serialUsingDouble: Int
    @Published var concurrentPerformUsingCoreData: Int
    @Published var concurrentPerformUsingDouble: Int

    @Published var serialUsingCoreDataValue: Double
    @Published var serialUsingDoubleValue: Double
    @Published var concurrentPerformUsingCoreDataValue: Double
    @Published var concurrentPerformUsingDoubleValue: Double


    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        self.serialUsingCoreData = 0
        self.serialUsingDouble = 0
        self.concurrentPerformUsingCoreData = 0
        self.concurrentPerformUsingDouble = 0

        self.serialUsingCoreDataValue = 0
        self.serialUsingDoubleValue = 0
        self.concurrentPerformUsingCoreDataValue = 0
        self.concurrentPerformUsingDoubleValue = 0
    }

    func calculateSerialUsingCoreData(_ item: Item) {
        let startTime = CFAbsoluteTimeGetCurrent()
        var result: Double = 0
        for _ in 0..<numberOfOuterLoopIterations {
            // create copy of the sourceItem in a childContext so we don't mutate the original
            let childContext = persistenceController.container.newBackgroundContext()
            childContext.performAndWait {
                let childObject: Item = try! childContext.existingObject(with: item.objectID) as! Item
                result = calculatePi(item: childObject)
            }
        }
        let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        serialUsingCoreData = elapsedTime
        serialUsingCoreDataValue = result
        print("serialUsingCoreData: \(elapsedTime)")
    }

    func calculateSerialUsingDouble(_ item: Item) {
        let itemAsDoubles: Double = item.valueMO
        var result: Double = 0
        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<numberOfOuterLoopIterations {
            result = calculatePi(structItem: StructItem(valueMO: itemAsDoubles))
        }
        let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        serialUsingDouble = elapsedTime
        serialUsingDoubleValue = result
        print("serialUsingArray: \(elapsedTime)")
    }

    func calculateConcurrentPerformUsingDouble(_ item: Item) {
        let itemAsDoubles: Double = item.valueMO
        var result: Double = 0
        let startTime = CFAbsoluteTimeGetCurrent()

        let concurrentQueue = DispatchQueue.init(label: "ConcurrentPerformUsingArray", qos: .userInitiated, attributes: .concurrent)

        concurrentQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.numberOfOuterLoopIterations) { index in
                result = self.calculatePi(structItem: StructItem(valueMO: itemAsDoubles))
            }
            DispatchQueue.main.async {
                let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
                self.concurrentPerformUsingDouble = elapsedTime
                self.concurrentPerformUsingDoubleValue = result
                print("concurrentPerformUsingDouble: \(elapsedTime)")
            }
        }
    }

    func calculateConcurrentPerformUsingCoreData(_ item: Item) {
        let startTime = CFAbsoluteTimeGetCurrent()
        var result: Double = 0

        let concurrentQueue = DispatchQueue.init(label: "ConcurrentPerformUsingArray", qos: .userInitiated, attributes: .concurrent)

        concurrentQueue.async {
            DispatchQueue.concurrentPerform(iterations: self.numberOfOuterLoopIterations) { index in
                // create copy of the sourceItem in a childContext so we don't mutate the original
                let sourceItem: Item = item
                guard let parentContext = sourceItem.managedObjectContext else {
                    // we shouldn't be passing a managed object without a context to this init...
                    fatalError("Attempting to edit a managed object that's not associated with a context")
                }

                let childContext = self.persistenceController.container.newBackgroundContext()

                childContext.performAndWait {
                    guard let childObject = try? childContext.existingObject(with: sourceItem.objectID) as? Item else {
                        fatalError("Attempting to edit a managed object that's not associated with a context")
                    }
                    result = self.calculatePi(item: childObject)
                }
            }
            DispatchQueue.main.async {
                let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
                self.concurrentPerformUsingCoreData = elapsedTime
                self.concurrentPerformUsingCoreDataValue = result
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


    func calculatePi(structItem: StructItem) -> Double {
        var item = structItem
        item.valueMO = 0.0
        var sign = 1.0
        for i in 0 ..< numberOfInnerLoopIterations {
            item.valueMO += sign / Double(i * 2 + 1)
            sign *= -1
        }
        item.valueMO = item.valueMO * 4
        return item.valueMO
    }

    func calculatePi(item: Item) -> Double {
        item.valueMO = 0.0
        var sign = 1.0
        for i in 0 ..< numberOfInnerLoopIterations {
            item.valueMO += sign / Double(i * 2 + 1)
            sign *= -1
        }
        item.valueMO = item.valueMO * 4
        return item.valueMO
    }

    struct StructItem {
        var valueMO: Double = 0
    }

}

