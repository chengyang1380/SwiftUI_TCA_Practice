//
//  GameResultListView.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 4/30/25.
//

import ComposableArchitecture
import SwiftUI

struct GameResultListView: View {

    @Bindable var store: StoreOf<GameResultListFeature>

    var body: some View {
        List {
            ForEach(store.state.results) { result in
                HStack {
                    Image(systemName: result.correct ? "checkmark.circle" : "x.circle")
                    Text("Secret: \(result.counter.secret)")
                    Text("Answer: \(result.counter.count)")
                }.foregroundColor(result.correct ? .green : .red)
            }.onDelete { store.send(.remove(offset: $0)) }
        }
        .toolbar {
            EditButton()
        }
    }
}

#Preview {
    GameResultListView(
        store: Store(initialState: GameResultListFeature.State(results: [
            GameResult.init(counter: .init(count: 10, secret: 10, id: .init()), spentTime: 100),
            GameResult.init(counter: .init(), spentTime: 100)
        ])) {
            GameResultListFeature()
        }
    )
}
