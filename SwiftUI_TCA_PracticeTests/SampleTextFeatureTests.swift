//
//  SampleTextFeatureTests.swift
//  SwiftUI_TCA_PracticeTests
//
//  Created by ChengYangChen on 3/31/25.
//

import Testing
import Foundation
import ComposableArchitecture

@testable import SwiftUI_TCA_Practice

@MainActor
struct SampleTextFeatureTests {

    let scheduler = DispatchQueue.test

    @Test
    func sampleTextRequest() async throws {
        let store = TestStore(initialState: SampleTextFeature.State()) {
            SampleTextFeature()
        } withDependencies: {
            $0.sampleTextFeatureEnvironment.loadText = {
                return .run { send in
                    await send(.success("Hello, World!"))
                }
            }
            $0.sampleTextFeatureEnvironment.queue = scheduler.eraseToAnyScheduler() // .immediate
        }

        await store.send(.load) {
            $0.loading = true
        }

        await scheduler.advance() // 替換 .immediate 即可刪除

        await store.receive(.loaded(.success("Hello, World!"))) {
            $0.loading = false
            $0.text = "Hello, World!"
        }
    }

}
