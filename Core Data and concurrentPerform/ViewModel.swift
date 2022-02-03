//
//  ViewModel.swift
//  Core Data and concurrentPerform
//
//  Created by Ryan Hamilton on 1/31/22.
//

import SwiftUI
import CoreData

@MainActor
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

    func calculateSerialUsingCoreData(_ sourceItem: Item) {
        Task {
            async let calculationResult = ConcurrentCalculator.calculateSerialUsingCoreData(sourceItem, persistenceController: self.persistenceController)
            (serialUsingCoreData, serialUsingCoreDataValue) = await calculationResult
        }
    }

    func calculateSerialUsingDouble(_ sourceItem: Item) {
        Task {
            async let calculationResult = ConcurrentCalculator.calculateSerialUsingDouble(sourceItem)
            (serialUsingDouble, serialUsingDoubleValue) = await calculationResult
        }
    }

    func calculateConcurrentPerformUsingDouble(_ sourceItem: Item) {
        Task {
            async let calculationResult = ConcurrentCalculator.calculateConcurrentPerformUsingDouble(sourceItem)
            (concurrentPerformUsingDouble, concurrentPerformUsingDoubleValue) = await calculationResult
        }
    }

    func calculateConcurrentPerformUsingCoreData(_ sourceItem: Item) {
        Task {
            async let calculationResult = ConcurrentCalculator.calculateConcurrentPerformUsingCoreData(sourceItem, persistenceController: self.persistenceController)
            (concurrentPerformUsingCoreData, concurrentPerformUsingCoreDataValue) = await calculationResult
        }
    }
}

