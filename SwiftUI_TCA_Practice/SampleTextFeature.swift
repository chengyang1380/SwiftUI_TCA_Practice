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
        var queue: AnySchedulerOf<DispatchQueue>
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .load:
                state.loading = true
                return .run { send in
                    try await environment.queue.sleep(for: .zero)
                }.concatenate(
                    with:
                        environment.loadText()
                        .map { .loaded($0) }
                )
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
    static var sampleRequest: Effect<Result<String, URLError>> {
        .run { send in
            let request = URLRequest(
                url: URL(string: "https://example.com/sample-text")!
            )
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = String(data: data, encoding: .utf8) ?? ""
            await send(.success(result))
        }
    }

    static var liveValue = Self(
        loadText: { sampleRequest },
        queue: .global()
    )

    static var testValue = Self(
        loadText: { .run { send in await send(.success("Hello, World!")) } },  // send(.failure(URLError.init(.badURL))) }}
        queue: .global()
    )
}

extension DependencyValues {
    var sampleTextFeatureEnvironment: SampleTextFeature.Environment {
        get { self[SampleTextFeature.Environment.self] }
        set { self[SampleTextFeature.Environment.self] = newValue }
    }
}
