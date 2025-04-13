//
//  SampleTextFeatureTests.swift
//  SwiftUI_TCA_PracticeTests
//
//  Created by ChengYangChen on 3/31/25.
//

import Testing
import ComposableArchitecture

@testable import SwiftUI_TCA_Practice

@MainActor
struct SampleTextFeatureTests {

    @Test
    func sampleTextRequest() async throws {
        let store = TestStore(initialState: SampleTextFeature.State()) {
            SampleTextFeature()
        }
        
        await store.send(.load) {
            $0.loading = true
        }

        await store.receive(.loaded(.success("Hello, World!"))) {
            $0.loading = false
            $0.text = "Hello, World!"
        }
    }

}
