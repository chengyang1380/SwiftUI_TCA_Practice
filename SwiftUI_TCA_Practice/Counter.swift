//
//  Counter.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 3/16/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct Counter {

    @Dependency(\.counterEnvironment) var environment

    @ObservableState
    struct State: Equatable {
        var count: Int = 0
        var secret = Int.random(in: -100...100)

        var id: UUID = UUID()
    }

    enum Action {
        case increment
        case decrement
        case setCount(String)
        case playNext
        case slidingCount(Float)
    }

    struct Environment {
        var generateRandom: (ClosedRange<Int>) -> Int
        var uuid: () -> UUID
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .decrement:
                state.count -= 1
            case .increment:
                state.count += 1
            case .setCount(let text):
                state.countString = text
            case .slidingCount(let value):
                state.countFloat = value
            case .playNext:
                state.count = 0
                state.secret = environment.generateRandom(-100...100)
                state.id = environment.uuid()
            }
            return .none
        }
        ._printChanges()
    }
}

extension Counter.State {
    var countString: String {
        get { String(count) }
        set { count = Int(newValue) ?? count }
    }

    var countFloat: Float {
        get { Float(count) }
        set { count = Int(newValue) }
    }

    enum CheckResult {
        case lower, equal, higher
    }

    var checkResult: CheckResult {
        if count < secret { return .lower }
        if count > secret { return .higher }
        return .equal
    }
}

extension Counter.Environment: DependencyKey {
    static let liveValue = Self(
        generateRandom: { Int.random(in: $0) },
        uuid: { UUID() }
    )

    static let testValue: Counter.Environment = .init(
        generateRandom: { _ in 1 },
        uuid: { UUID(1) }
    )
}

extension DependencyValues {
    var counterEnvironment: Counter.Environment {
        get { self[Counter.Environment.self] }
        set { self[Counter.Environment.self] = newValue }
    }
}
