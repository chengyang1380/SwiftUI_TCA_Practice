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
            CounterView(
                store: Store(
                    initialState: Counter.State(),
                    reducer: {
                        Counter()
                    },
                    withDependencies: {
                        $0.counterEnvironment = .live
                    }))
        }
    }
}
