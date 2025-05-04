//
//  GameView.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 4/13/25.
//

import ComposableArchitecture
import SwiftUI

struct GameView: View {

    @Bindable var store: StoreOf<GameFeature>

    var body: some View {
        VStack {
            resultLabel(store.state.results)
            Divider()
            TimerLabel(store: store.scope(state: \.timer, action: \.timer))
            CounterView(store: store.scope(state: \.counter, action: \.counter))
        }.onAppear {
            store.send(.timer(.start))
        }
    }

    func resultLabel(_ results: IdentifiedArrayOf<GameResult>) -> some View {
        VStack {
            Text("Result: \(results.filter(\.correct).count)/\(results.count) correct")
            Spacer()
        }
    }
}

#Preview {
    GameView(
        store: Store(initialState: GameFeature.State()) {
            GameFeature()
        } withDependencies: {
            $0.gameFeatureEnvironment = .liveValue
        }
    )
}
