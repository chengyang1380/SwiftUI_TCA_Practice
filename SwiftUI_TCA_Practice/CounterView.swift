//
//  CounterView.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 3/13/25.
//

import ComposableArchitecture
import SwiftUI

struct CounterView: View {

    @Bindable var store: StoreOf<Counter>

    var body: some View {
        VStack {
            checkLabel(with: store.checkResult)
            HStack {
                Button("-") { store.send(.decrement) }
                TextField(
                    String(store.count),
                    text: Binding(
                        get: { store.countString },
                        set: { store.send(.setCount($0)) }
                    )
                )
                .multilineTextAlignment(.center)
                .foregroundColor(colorOfCount(store.count))
                .frame(width: 40)
                Button("+") { store.send(.increment) }
            }

            Slider(
                value: Binding(
                    get: { store.countFloat },
                    set: { store.send(.slidingCount($0)) }
                ), in: -100...100
            )
            .frame(maxWidth: 300)

            Button {
                store.send(.playNext)
            } label: {
                Text("Next")
            }
            .frame(width: 150)
        }
    }

    func checkLabel(with checkResult: Counter.State.CheckResult) -> some View {
        switch checkResult {
        case .lower:
            return Label("Lower", systemImage: "lessthan.circle")
                .foregroundColor(.red)
        case .higher:
            return Label("Higher", systemImage: "greaterthan.circle")
                .foregroundColor(.red)
        case .equal:
            return Label("Correct", systemImage: "checkmark.circle")
                .foregroundColor(.green)
        }
    }

    func colorOfCount(_ value: Int) -> Color? {
        if value == 0 { return nil }
        return value < 0 ? .red : .green
    }
}

#Preview("Counter") {
    CounterView(
        store: Store(initialState: Counter.State()) {
            Counter()
        } withDependencies: {
            $0.counterEnvironment = .testValue
        }
    )
}
