//
//  TimerLabel.swift
//  SwiftUI_TCA_Practice
//
//  Created by ChengYangChen on 3/16/25.
//

import ComposableArchitecture
import SwiftUI

struct TimerLabel: View {
    @Bindable var store: StoreOf<TimerFeature>

    var body: some View {
        VStack(alignment: .leading) {
            Label(
                store.state.started == nil
                    ? "-"
                    : "\(store.started!.formatted(date: .omitted, time: .standard))",
                systemImage: "clock"
            )
            Label(
                "\(store.duration, format: .number)s",
                systemImage: "timer"
            )
        }
    }
}

#Preview("TimerLabel") {
    let store = Store(initialState: TimerFeature.State()) {
        TimerFeature()
    }
    VStack {
        TimerLabel(store: store)
        HStack {
            Button("Start") { store.send(.start) }
            Button("Stop") { store.send(.stop) }
        }.padding()
    }
}
