//
//  CounterView.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 3/13/25.
//

import ComposableArchitecture
import SwiftUI

// MARK: - View Model
@Reducer
struct Counter {

    @ObservableState
    struct State: Equatable {
        var count: Int = 0
        var secret = Int.random(in: -100...100)
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

        static let live: Self = .init(generateRandom: Int.random(in:))
    }

    struct EnvironmentKey: DependencyKey {
        static let liveValue = Environment(generateRandom: { range in
            Int.random(in: range)
        })
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
                state.secret = DependencyValues().counterEnvironment
                    .generateRandom(-100...100)
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
}

extension Counter.State {
    enum CheckResult {
        case lower, equal, higher
    }

    var checkResult: CheckResult {
        if count < secret { return .lower }
        if count > secret { return .higher }
        return .equal
    }
}

extension DependencyValues {
    var counterEnvironment: Counter.Environment {
        get { self[Counter.EnvironmentKey.self] }
        set { self[Counter.EnvironmentKey.self] = newValue }
    }
}

// MARK: - View
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
        })
}
