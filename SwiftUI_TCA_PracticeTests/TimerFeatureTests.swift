//
//  TimerFeatureTests.swift
//  SwiftUI_TCA_PracticeTests
//
//  Created by ChengYangChen on 3/16/25.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import SwiftUI_TCA_Practice

@MainActor
struct TimerFeatureTests {
    let clock = TestClock()
    
    @Test
    func testTimerStartAndStop() async throws {
        let store = TestStore(
            initialState: TimerFeature.State(),
            reducer: {
                TimerFeature()
            },
            withDependencies: {
                $0.continuousClock = clock
                $0.date = DateGenerator({ Date(timeIntervalSince1970: 100) })
            })
        
        await store.send(.start) {
            $0.started = Date(timeIntervalSince1970: 100)
            $0.duration = 0
        }
        await clock.advance(by: .milliseconds(30))
        
        await store.receive(.timeUpdated) {
            $0.duration = 0.01
        }
        
        await store.receive(.timeUpdated) {
            $0.duration = 0.02
        }
        
        await store.receive(.timeUpdated) {
            $0.duration = 0.03
        }
        
        await store.send(.stop)
        
        await clock.advance(by: .milliseconds(50))
    }
}
