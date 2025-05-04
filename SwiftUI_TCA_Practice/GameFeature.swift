//
//  GameFeature.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 4/13/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct GameFeature {
    @Dependency(\.gameFeatureEnvironment) var environment

    @ObservableState
    struct State: Equatable {
        var counter: Counter.State = .init()
        var timer: TimerFeature.State = .init()

        var results = IdentifiedArrayOf<GameResult>()
        var lastTimestamp = 0.0
    }

    enum Action {
        case counter(Counter.Action)
        case timer(TimerFeature.Action)
    }

    struct Environment {
        var generateRandom: (ClosedRange<Int>) -> Int
        var uuid: () -> UUID
        var date: () -> Date
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .counter(.playNext):
                let result = GameResult(
                    counter: state.counter,
                    spentTime: state.timer.duration - state.lastTimestamp
                )
                state.results.append(result)
                state.lastTimestamp = state.timer.duration
                return .none
            default: return .none
            }
        }
        Scope(state: \.counter, action: \.counter) {
            Counter()
        }.transformDependency(\.counterEnvironment) { dependency in
            dependency.generateRandom = environment.generateRandom
            dependency.uuid = environment.uuid
        }
        Scope(state: \.timer, action: \.timer) {
            TimerFeature()
        }.transformDependency(\.date) { dependency in
            dependency.now = environment.date()
        }
    }
}

extension GameFeature.Environment: DependencyKey {
    static let liveValue = Self(
        generateRandom: { Int.random(in: $0) },
        uuid: { UUID() },
        date: { Date() }
    )

    static let testValue = Self(
        generateRandom: { _ in 1 },
        uuid: { UUID() },
        date: { Date(timeIntervalSince1970: 300_000) }
    )
}

extension DependencyValues {
    var gameFeatureEnvironment: GameFeature.Environment {
        get { self[GameFeature.Environment.self] }
        set { self[GameFeature.Environment.self] = newValue }
    }
}

struct GameResult: Equatable, Identifiable {
    let counter: Counter.State
    let spentTime: TimeInterval

    var correct: Bool { counter.secret == counter.count }
    var id: UUID { counter.id }
}
