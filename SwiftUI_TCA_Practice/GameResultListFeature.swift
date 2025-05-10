//
//  GameResultListFeature.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 5/4/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct GameResultListFeature {
    @ObservableState
    struct State: Equatable {
        var results: IdentifiedArrayOf<GameResult> = []
    }

    enum Action {
        case remove(offset: IndexSet)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .remove(let offset):
                state.results.remove(atOffsets: offset)
                return .none
            }
        }
    }
}
