//
//  ConcurrentCalculator.swift
//  Core Data and concurrentPerform
//
//  Created by Ryan Hamilton on 2/3/22.
//

import Foundation
import CoreData

struct ConcurrentCalculator {
    static let numberOfOuterLoopIterations = 200
    static let numberOfInnerLoopIterations: Int = 5_000_00

    static func calculateSerialUsingCoreData(_ sourceItem: Item, persistenceController: PersistenceController) -> (Int, Double) {
        let startTime = CFAbsoluteTimeGetCurrent()
        var result: Double = 0
        for _ in 0..<numberOfOuterLoopIterations {
            // create copy of the sourceItem in a childContext so we don't mutate the original

            let backgroundContext = persistenceController.container.newBackgroundContext()
            backgroundContext.performAndWait {
                let childObject: Item = try! backgroundContext.existingObject(with: sourceItem.objectID) as! Item
                result = calculatePi(item: childObject)
            }
        }
        let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        print("serialUsingCoreData: \(elapsedTime)")
        return (elapsedTime, result)
    }

    static func calculateSerialUsingDouble(_ item: Item) -> (Int, Double) {
        var result: Double = 0
        let startTime = CFAbsoluteTimeGetCurrent()
        for _ in 0..<numberOfOuterLoopIterations {
            result = calculatePi(structItem: StructItem(valueMO: item.valueMO))
        }
        let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        print("serialUsingArray: \(elapsedTime)")
        return (elapsedTime, result)
    }

    static func calculateConcurrentPerformUsingDouble(_ item: Item) -> (Int, Double) {
        var result: Double = 0
        let startTime = CFAbsoluteTimeGetCurrent()

        let concurrentQueue = DispatchQueue.init(label: "ConcurrentPerformUsingArray", qos: .userInitiated, attributes: .concurrent)

        concurrentQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.numberOfOuterLoopIterations) { index in
                result = self.calculatePi(structItem: StructItem(valueMO: item.valueMO))
            }
        }
        let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        return (elapsedTime, result)
    }

    static func calculateConcurrentPerformUsingCoreData(_ item: Item, persistenceController: PersistenceController) -> (Int, Double) {
        let startTime = CFAbsoluteTimeGetCurrent()
        var result: Double = 0

        let concurrentQueue = DispatchQueue.init(label: "ConcurrentPerformUsingArray", qos: .userInitiated, attributes: .concurrent)

        concurrentQueue.sync {
            DispatchQueue.concurrentPerform(iterations: self.numberOfOuterLoopIterations) { index in
                // create copy of the sourceItem in a childContext so we don't mutate the original
                let sourceItem: Item = item

                let backgroundContext = persistenceController.container.newBackgroundContext()
                backgroundContext.performAndWait {
                    guard let childObject = try? backgroundContext.existingObject(with: sourceItem.objectID) as? Item else {
                        fatalError("Attempting to edit a managed object that's not associated with a context")
                    }
                    result = self.calculatePi(item: childObject)
                }
            }
        }
        let elapsedTime = Int((CFAbsoluteTimeGetCurrent() - startTime)*1000)
        return (elapsedTime, result)
    }

    // This function uses a struct property for internal storage.
    static func calculatePi(structItem: StructItem) -> Double {
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

    // This function uses a NSManagedObject for its internal calculations.
    // It takes 30x longer to run this function that the one using a struct.
    static func calculatePi(item: Item) -> Double {
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
