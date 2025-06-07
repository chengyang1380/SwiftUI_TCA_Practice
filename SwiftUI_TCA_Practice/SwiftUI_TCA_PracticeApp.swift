//
//  SwiftUI_TCA_PracticeApp.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 3/13/25.
//

import ComposableArchitecture
import SwiftUI

@main
struct SwiftUI_TCA_PracticeApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GameView(
                    store: Store(
                        initialState: testState,
                        reducer: {
                            GameFeature()
                        }
                    )
                )
            }
        }
    }
}

let sample = GameResultListFeature.State(results: [
    .init(counter: .init(count: 10, secret: 10, id: .init()), spentTime: 100),
    .init(counter: .init(), spentTime: 500),
])

let testState = GameFeature.State(
    counter: .init(),
    timer: .init(),
    resultState: sample,
    lastTimestamp: 100
//    resultListState: .init(sample, id: resultListStateTag)
)
