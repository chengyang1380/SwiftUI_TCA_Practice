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
    @Dependency(\.dismiss) var dissmiss

    @ObservableState
    struct State: Equatable {
        var counter: Counter.State = .init()
        var timer: TimerFeature.State = .init()

        var resultState: GameResultListFeature.State = .init()
        var lastTimestamp = 0.0
        var resultListState: Identified<UUID, GameResultListFeature.State>?
        @Presents var alert: AlertState<GameAlertAction>?
    }

    enum Action {
        case counter(Counter.Action)
        case timer(TimerFeature.Action)
        case listResult(GameResultListFeature.Action)
        case setNavigation(UUID?)
        case alertAction(PresentationAction<GameAlertAction>)
    }

    enum GameAlertAction: Equatable {
        case alertSaveButtonTapped
        case alertCancelButtonTapped
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
                state.resultState.results.append(result)
                state.lastTimestamp = state.timer.duration
                return .none
            case .setNavigation(.some(let id)):
                state.resultListState = .init(state.resultState, id: id)
                return .none
            case .setNavigation(.none):
                if state.resultListState?.value.results != state.resultState.results {
                    state.alert = .init(
                        title: { TextState("Save Changes?") },
                        actions: {
                            ButtonState<GameFeature.GameAlertAction>.init(
                                action: .send(.alertSaveButtonTapped),
                                label: { .init("OK") }
                            )
                            ButtonState<GameFeature.GameAlertAction>.init(
                                role: .cancel,
                                action: .send(.alertCancelButtonTapped),
                                label: { .init("Cancel") }
                            )
                        }
                    )
                } else {
                    state.resultListState = nil
                }
                return .none
            case .alertAction(.dismiss):
                state.alert = nil
                return .none
            case .alertAction(.presented(.alertSaveButtonTapped)):
                if let newState = state.resultListState?.value {
                    state.resultState = newState
                }
                state.resultListState = nil
                return .none
            case .alertAction(.presented(.alertCancelButtonTapped)):
                state.resultListState = nil
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
        Scope(state: \.resultListState!.value, action: \.listResult) {
            GameResultListFeature()
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
