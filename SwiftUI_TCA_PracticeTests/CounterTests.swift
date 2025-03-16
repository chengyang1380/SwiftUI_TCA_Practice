//
//  CounterTests.swift
//  SwiftUI_TCA_PracticeTests
//
//  Created by ChengYangChen on 3/15/25.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import SwiftUI_TCA_Practice

@MainActor
struct CounterTests {

    let store: TestStore<Counter.State, Counter.Action>

    init() {
        store = TestStore(initialState: Counter.State()) {
            Counter()
        } withDependencies: {
            $0.counterEnvironment = .init(
                generateRandom: { _ in 10 },
                uuid: { .dummy }
            )
        }
    }
}

extension CounterTests {
    @Test
    func increment() async throws {
        await store.send(.increment) {
            $0.count = 1
        }
    }

    @Test
    func decrement() async throws {
        await store.send(.decrement) {
            $0.count = -1
        }
    }
    
    @Test
    func setCount() async throws {
        await store.send(.setCount("50")) {
            $0.count = 50
        }
    }
    
    @Test
    func playNext() async throws {
        await store.send(.playNext) {
            $0.count = 0
            $0.secret = 10
            $0.id = .dummy
        }
    }
    
    @Test
    func slidingCount() async throws {
        await store.send(.slidingCount(-50.0)) {
            $0.count = -50
        }
    }
}

// MARK: - Helper
extension UUID {
  static let dummy = UUID(uuidString: "ABABABAB-CDCD-EFEF-ABAB-CDCDCDCDCDCD")!
}
