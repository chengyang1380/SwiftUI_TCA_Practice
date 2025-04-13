//
//  SampleTextFeature.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 3/17/25.
//

import ComposableArchitecture
import Foundation

@Reducer
struct SampleTextFeature {

    @Dependency(\.sampleTextFeatureEnvironment) var environment

    @ObservableState
    struct State: Equatable {
        var loading: Bool = false
        var text: String = ""
    }

    enum Action: Equatable {
        case load
        case loaded(Result<String, URLError>)
    }

    struct Environment {
        var loadText: () -> Effect<Result<String, URLError>>
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .load:
                state.loading = true
                return environment.loadText()
                    .map { .loaded($0) }
            case .loaded(let result):
                state.loading = false
                do {
                    state.text = try result.get()
                } catch {
                    state.text = "Error: \(error)"
                }
            }
            return .none
        }
    }
}

extension SampleTextFeature.Environment: DependencyKey {
    static var liveValue = Self(
        loadText: { .run { send in await send(.success("Hello, World!")) } }  // throw some error }}
    )

    static var testValue = Self(
        loadText: { .run { send in await send(.success("Hello, World!")) } }  // send(.failure(URLError.init(.badURL))) }}
    )
}

extension DependencyValues {
    var sampleTextFeatureEnvironment: SampleTextFeature.Environment {
        get { self[SampleTextFeature.Environment.self] }
        set { self[SampleTextFeature.Environment.self] = newValue }
    }
}
