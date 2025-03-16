//
//  TimerFeature.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 3/16/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct TimerFeature {
    @ObservableState
    struct State: Equatable {
        var started: Date? = nil
        var duration: TimeInterval = 0
    }

    enum Action {
        case start
        case stop
        case timeUpdated
    }

    @Dependency(\.date) var date
    @Dependency(\.continuousClock) var clock

    struct TimerID: Hashable {}

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .start:
                if state.started == nil {
                    state.started = date()
                    state.duration = 0
                }
                return .run { send in
                    for await _ in self.clock.timer(
                        interval: .milliseconds(10))
                    {
                        await send(.timeUpdated)
                    }
                }
                .cancellable(id: TimerID())
            case .timeUpdated:
                state.duration += 0.01
                return .none
            case .stop:
                return .cancel(id: TimerID())
            }
        }
    }
}
